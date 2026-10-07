#if os(macOS) && !APP_STORE
    import Foundation
    import Network

    /// Reject redirects outside GitHub's credential-free artifact delivery hosts.
    final class UpdateRedirectPolicy: NSObject, URLSessionDownloadDelegate, Sendable {
        let maximum: Int64
        init(maximum: Int64 = 512 * 1024 * 1024) { self.maximum = maximum }
        func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask,
                        didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            if totalBytesWritten > maximum || totalBytesExpectedToWrite > maximum { downloadTask.cancel() }
        }

        func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo _: URL) {}
        func urlSession(_: URLSession, task _: URLSessionTask,
                        willPerformHTTPRedirection _: HTTPURLResponse, newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
            guard let url = request.url, url.scheme == "https", url.user == nil, url.password == nil,
                  url.port == nil || url.port == 443,
                  ["release-assets.githubusercontent.com", "objects.githubusercontent.com"].contains(url.host) else {
                completionHandler(nil)
                return
            }
            var clean = request
            clean.setValue(nil, forHTTPHeaderField: "Authorization")
            clean.setValue(nil, forHTTPHeaderField: "Cookie")
            completionHandler(clean)
        }
    }

    struct PrivateUpdateRelease: Decodable, Sendable {
        struct Asset: Decodable, Sendable {
            let id: Int
            let name: String
            let size: Int
            let state: String
            init(id: Int, name: String, size: Int, state: String = "uploaded") {
                self.id = id
                self.name = name
                self.size = size
                self.state = state
            }
        }

        let id: Int
        enum CodingKeys: String, CodingKey { case id, tagName = "tag_name", draft, prerelease, assets }
        let tagName: String
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]

        func completeArchive(app: String, suffix: String = "-universal.zip") -> Asset? {
            guard !draft, !prerelease,
                  tagName.range(of: #"^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$"#,
                                options: .regularExpression) != nil,
                  assets.count(where: { $0.name == "appcast.xml" && $0.size > 0 && $0.state == "uploaded" }) == 1,
                  assets.count(where: { $0.name == "release.json" && $0.size > 0 && $0.state == "uploaded" }) == 1 else { return nil }
            let archive = app + "-" + String(tagName.dropFirst()) + suffix
            let matches = assets.filter { $0.name == archive && $0.state == "uploaded" && $0.size > 0 && $0.size <= 512 * 1024 * 1024 }
            return matches.count == 1 ? matches[0] : nil
        }
    }

    final class UpdateFeedValidator: NSObject, XMLParserDelegate {
        private(set) var enclosures: [[String: String]] = []
        private(set) var invalid = false
        func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?,
                    qualifiedName _: String?, attributes attributeDict: [String: String]) {
            if elementName == "enclosure" { enclosures.append(attributeDict) }
            if elementName.hasSuffix("releaseNotesLink") || elementName.hasSuffix("fullReleaseNotesLink") {
                invalid = true
            }
        }

        static func validate(_ data: Data, asset: PrivateUpdateRelease.Asset, repository: String) throws -> URL {
            guard data.count <= 1024 * 1024 else { throw PrivateUpdateTransport.Failure.invalidFeed }
            let parser = XMLParser(data: data)
            parser.shouldResolveExternalEntities = false
            let delegate = UpdateFeedValidator()
            parser.delegate = delegate
            guard parser.parse(), !delegate.invalid, delegate.enclosures.count == 1,
                  let enclosure = delegate.enclosures.first,
                  let url = URL(string: enclosure["url"] ?? ""),
                  url.scheme == "https", url.host == "api.github.com", url.user == nil, url.password == nil,
                  url.port == nil || url.port == 443,
                  url.path == "/repos/" + repository + "/releases/assets/" + String(asset.id),
                  url.fragment == nil,
                  URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems == [URLQueryItem(name: "filename", value: asset.name)],
                  Int(enclosure["length"] ?? "") == asset.size,
                  let signature = enclosure["sparkle:edSignature"],
                  Data(base64Encoded: signature)?.count == 64 else {
                throw PrivateUpdateTransport.Failure.invalidFeed
            }
            return url
        }
    }

    /// Only this transport holds credentials. Sparkle accesses nonce-scoped loopback routes.
    @MainActor
    final class PrivateUpdateTransport {
        enum Failure: LocalizedError {
            case access, noCompleteRelease, invalidFeed, unexpectedResponse, bridge
            var errorDescription: String? {
                switch self {
                case .access: "GitHub update access is unavailable or rate limited. Public updates normally need no token; optionally configure read-only GitHub access and retry."
                case .noCompleteRelease: "No completed signed update is available yet."
                case .invalidFeed: "The release update metadata is incomplete or invalid."
                case .unexpectedResponse: "The update download did not match the completed release."
                case .bridge: "Could not prepare the local update connection."
                }
            }
        }

        let repository: String
        let app: String
        let archiveSuffix: String
        var failureHandler: (@MainActor (any Error) -> Void)?
        private let session: URLSession
        private let sessionConfiguration: URLSessionConfiguration
        private var listener: NWListener?
        private var bridgeContinuation: CheckedContinuation<NWEndpoint.Port, any Error>?
        private var nonce = UUID().uuidString
        private var feed = Data()
        private var archiveAsset: PrivateUpdateRelease.Asset?
        private var archiveFile: URL?
        private var tokenProvider: (@MainActor () throws -> String?)?
        private var preparing = false
        private(set) var feedURL: URL?
        private(set) var archiveURL: URL?
        private(set) var sourceArchiveURL: URL?

        init(repository: String, app: String, archiveSuffix: String = "-universal.zip", configuration: URLSessionConfiguration = .ephemeral) {
            self.repository = repository
            self.app = app
            self.archiveSuffix = archiveSuffix
            let config = configuration
            config.httpCookieStorage = nil
            config.urlCache = nil
            config.timeoutIntervalForRequest = 60
            sessionConfiguration = config
            session = URLSession(configuration: config, delegate: UpdateRedirectPolicy(), delegateQueue: nil)
        }

        private func fetch(path: String, token: String?, binary: Bool, maximum: Int) async throws -> Data {
            let url = URL(string: "https://api.github.com/repos/" + repository + "/" + path)!
            var request = URLRequest(url: url)
            if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
            request.setValue(binary ? "application/octet-stream" : "application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else { throw Failure.unexpectedResponse }
            if [401, 403, 404].contains(response.statusCode) { throw Failure.access }
            guard response.statusCode == 200, data.count <= maximum else { throw Failure.unexpectedResponse }
            return data
        }

        func prepare(token: String?, tokenProvider: @escaping @MainActor () throws -> String?) async throws {
            guard !preparing else { throw Failure.bridge }
            preparing = true
            defer { preparing = false }
            self.tokenProvider = tokenProvider
            let data = try await fetch(path: "releases?per_page=30", token: token, binary: false, maximum: 4 * 1024 * 1024)
            let releases = try JSONDecoder().decode([PrivateUpdateRelease].self, from: data)
            guard let release = releases.first(where: { $0.completeArchive(app: app, suffix: archiveSuffix) != nil }),
                  let asset = release.completeArchive(app: app, suffix: archiveSuffix),
                  let feedAsset = release.assets.first(where: { $0.name == "appcast.xml" }) else { throw Failure.noCompleteRelease }
            let nextFeed = try await fetch(path: "releases/assets/" + String(feedAsset.id), token: token, binary: true, maximum: 1024 * 1024)
            let source = try UpdateFeedValidator.validate(nextFeed, asset: asset, repository: repository)
            listener?.cancel()
            nonce = UUID().uuidString
            feed = nextFeed
            if let archiveFile { try? FileManager.default.removeItem(at: archiveFile) }
            archiveFile = nil
            archiveAsset = asset
            sourceArchiveURL = source
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
            let bridge = try NWListener(using: parameters)
            listener = bridge
            bridge.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.serve(connection) }
            }
            let port = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NWEndpoint.Port, any Error>) in
                bridgeContinuation = continuation
                bridge.stateUpdateHandler = { [weak self] state in
                    Task { @MainActor in
                        guard let self, let pending = self.bridgeContinuation else { return }
                        switch state {
                        case .ready:
                            self.bridgeContinuation = nil
                            if let port = bridge.port { pending.resume(returning: port) }
                            else { pending.resume(throwing: Failure.bridge) }
                        case .failed, .cancelled:
                            self.bridgeContinuation = nil
                            pending.resume(throwing: Failure.bridge)
                        default: break
                        }
                    }
                }
                bridge.start(queue: .main)
            }
            let base = "http://127.0.0.1:" + String(port.rawValue) + "/" + nonce + "/"
            feedURL = URL(string: base + "appcast.xml")
            archiveURL = URL(string: base + asset.name)
        }

        private func serve(_ connection: NWConnection) {
            connection.start(queue: .main)
            receiveHeader(connection, accumulated: Data())
        }

        private func receiveHeader(_ connection: NWConnection, accumulated: Data) {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 8192 - accumulated.count) { [weak self] data, _, complete, error in
                Task { @MainActor in
                    guard let self, let data, error == nil else { connection.cancel()
                        return
                    }
                    let header = accumulated + data
                    guard header.count <= 8192 else { connection.cancel()
                        return
                    }
                    if header.range(of: Data("\r\n\r\n".utf8)) == nil {
                        guard !complete, header.count < 8192 else { connection.cancel()
                            return
                        }
                        self.receiveHeader(connection, accumulated: header)
                        return
                    }
                    guard let request = String(data: header, encoding: .utf8),
                          let first = request.components(separatedBy: "\r\n").first else { connection.cancel()
                        return
                    }
                    let pieces = first.split(separator: " ")
                    guard pieces.count == 3, pieces[0] == "GET" else { connection.cancel()
                        return
                    }
                    let path = String(pieces[1])
                    let body: Data
                    let type: String
                    if path == self.feedURL?.path { body = self.feed
                        type = "application/xml"
                    } else if path == self.archiveURL?.path {
                        do { try await self.sendArchive(connection) }
                        catch {
                            self.failureHandler?(error)
                            connection.send(content: Data("HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8),
                                            completion: .contentProcessed { _ in connection.cancel() })
                        }
                        return
                    } else { connection.cancel()
                        return
                    }
                    let responseHeader = Data("HTTP/1.1 200 OK\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".utf8)
                    connection.send(content: responseHeader + body, completion: .contentProcessed { _ in connection.cancel() })
                }
            }
        }

        private func sendArchive(_ connection: NWConnection) async throws {
            guard let asset = archiveAsset, let tokenProvider else { throw Failure.bridge }
            if archiveFile == nil {
                let token = try tokenProvider()
                var request = URLRequest(url: URL(string: "https://api.github.com/repos/" + repository + "/releases/assets/" + String(asset.id))!)
                if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
                request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
                request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
                let config = sessionConfiguration.copy() as! URLSessionConfiguration
                config.httpCookieStorage = nil
                config.urlCache = nil
                let downloadSession = URLSession(configuration: config, delegate: UpdateRedirectPolicy(maximum: Int64(asset.size)), delegateQueue: nil)
                defer { downloadSession.invalidateAndCancel() }
                let (temporary, response) = try await downloadSession.download(for: request)
                guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                      try temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize == asset.size else { throw Failure.access }
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
                let destination = directory.appendingPathComponent(asset.name)
                try FileManager.default.moveItem(at: temporary, to: destination)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
                archiveFile = destination
            }
            guard let archiveFile else { throw Failure.bridge }
            let file = try FileHandle(forReadingFrom: archiveFile)
            defer { try? file.close() }
            try await send(Data("HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: \(asset.size)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".utf8), to: connection)
            while let chunk = try file.read(upToCount: 256 * 1024), !chunk.isEmpty {
                try Task.checkCancellation()
                try await send(chunk, to: connection)
            }
            connection.cancel()
        }

        private func send(_ data: Data, to connection: NWConnection) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume() }
                })
            }
        }
    }
#endif
