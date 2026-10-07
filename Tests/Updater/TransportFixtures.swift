import Foundation
import Synchronization

@main
struct UpdateTransportFixtures {
    @MainActor
    static func main() async throws {
        let signature = Data(repeating: 0, count: 64).base64EncodedString()
        let archive = PrivateUpdateRelease.Asset(id: 17, name: "Fixture-1.2.3-universal.zip", size: 123)
        let feed = Data("""
        <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item><enclosure url="https://api.github.com/repos/test/Fixture/releases/assets/17?filename=Fixture-1.2.3-universal.zip" length="123" sparkle:edSignature="\(
            signature
        )" /></item></channel></rss>
        """.utf8)
        _ = try UpdateFeedValidator.validate(feed, asset: archive, repository: "test/Fixture")
        for bad in [String(data: feed, encoding: .utf8)!.replacingOccurrences(of: "assets/17", with: "assets/18"),
                    String(data: feed, encoding: .utf8)!.replacingOccurrences(of: "test/Fixture", with: "test/Other"),
                    String(data: feed, encoding: .utf8)!.replacingOccurrences(
                        of: "length=\"123\"",
                        with: "length=\"124\""
                    ),
                    String(data: feed, encoding: .utf8)!.replacingOccurrences(
                        of: "api.github.com",
                        with: "evil.example"
                    ),
                    String(data: feed, encoding: .utf8)!.replacingOccurrences(
                        of: "</item>",
                        with: "<sparkle:releaseNotesLink>https://evil.example</sparkle:releaseNotesLink></item>"
                    ),
                    "<rss><channel>",
                    "<!DOCTYPE rss SYSTEM 'file:///etc/passwd'><rss/>"] {
            var failed = false
            do { _ = try UpdateFeedValidator.validate(Data(bad.utf8), asset: archive, repository: "test/Fixture") }
            catch { failed = true }
            precondition(failed, "Untrusted feed must fail")
        }
        let assets = [
            archive,
            .init(id: 18, name: "appcast.xml", size: 123),
            .init(id: 19, name: "release.json", size: 123),
        ]
        let release = PrivateUpdateRelease(id: 3, tagName: "v1.2.3", draft: false, prerelease: false, assets: assets)
        precondition(release.completeArchive(app: "Fixture") != nil)
        precondition(PrivateUpdateRelease(id: 3, tagName: "v1.2.3", draft: true, prerelease: false, assets: assets)
            .completeArchive(app: "Fixture") == nil)
        precondition(PrivateUpdateRelease(id: 3, tagName: "v1.2.3", draft: false, prerelease: true, assets: assets)
            .completeArchive(app: "Fixture") == nil)
        precondition(PrivateUpdateRelease(id: 3, tagName: "v1.2.3", draft: false, prerelease: false, assets: [archive])
            .completeArchive(app: "Fixture") == nil)
        precondition(!PrivateUpdateAccess.validToken("token with spaces"))
        precondition(PrivateUpdateAccess.validToken("github_pat_example123"))
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FixtureUpdateProtocol.self]
        let releases = """
        [{"id":3,"tag_name":"v1.2.3","draft":false,"prerelease":false,"assets":[{"id":17,"name":"Fixture-1.2.3-universal.zip","size":123,"state":"uploaded"},{"id":18,"name":"appcast.xml","size":500,"state":"uploaded"},{"id":19,"name":"release.json","size":123,"state":"uploaded"}]}]
        """
        FixtureUpdateProtocol.responses.withLock { value in
            value["/repos/test/Fixture/releases"] = Data(releases.utf8)
            value["/repos/test/Fixture/releases/assets/18"] = feed
        }
        let transport = PrivateUpdateTransport(repository: "test/Fixture", app: "Fixture", configuration: config)
        try await transport.prepare(token: nil) { nil }
        precondition(
            FixtureUpdateProtocol.paths.withLock { !$0.contains("/repos/test/Fixture/releases/assets/17") },
            "Checking must not download archives"
        )
        let (servedFeed, response) = try await URLSession.shared.data(from: transport.feedURL!)
        precondition(
            (response as? HTTPURLResponse)?.statusCode == 200 && servedFeed == feed,
            "Loopback must preserve feed bytes"
        )
        var redirected = URLRequest(url: URL(string: "https://release-assets.githubusercontent.com/fixture")!)
        redirected.setValue("Bearer github_pat_fixture", forHTTPHeaderField: "Authorization")
        redirected.setValue("session=fixture", forHTTPHeaderField: "Cookie")
        let redirectSession = URLSession(configuration: .ephemeral)
        let redirectTask = redirectSession.dataTask(with: URL(string: "https://api.github.com")!)
        let redirectResponse = HTTPURLResponse(
            url: URL(string: "https://api.github.com")!,
            statusCode: 302,
            httpVersion: nil,
            headerFields: nil
        )!
        UpdateRedirectPolicy().urlSession(
            redirectSession,
            task: redirectTask,
            willPerformHTTPRedirection: redirectResponse,
            newRequest: redirected
        ) { clean in
            precondition(clean?.value(forHTTPHeaderField: "Authorization") == nil)
            precondition(clean?.value(forHTTPHeaderField: "Cookie") == nil)
        }
        redirected.url = URL(string: "https://evil.example/fixture")!
        UpdateRedirectPolicy().urlSession(
            redirectSession,
            task: redirectTask,
            willPerformHTTPRedirection: redirectResponse,
            newRequest: redirected
        ) { clean in
            precondition(clean == nil)
        }
        FixtureUpdateProtocol.statuses.withLock { $0["/repos/test/Fixture/releases"] = 401 }
        let expired = PrivateUpdateTransport(repository: "test/Fixture", app: "Fixture", configuration: config)
        var denied = false
        do { try await expired.prepare(token: nil) { nil } }
        catch PrivateUpdateTransport.Failure.access { denied = true }
        precondition(denied, "Expired access must produce actionable failure")
        print("Update metadata, credential failure, cache-free loopback and redirect fixtures passed")
    }
}

final class FixtureUpdateProtocol: URLProtocol, @unchecked Sendable {
    static let responses = Mutex<[String: Data]>([:])
    static let paths = Mutex<[String]>([])
    static let statuses = Mutex<[String: Int]>([:])
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "api.github.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        precondition(request.value(forHTTPHeaderField: "Authorization") == nil, "Public updates must not need a token")
        let path = request.url!.path
        Self.paths.withLock { $0.append(path) }
        let body = Self.responses.withLock { $0[path] }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statuses.withLock { $0[path] } ?? (body == nil ? 404 : 200),
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
