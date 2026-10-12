#if os(macOS) && !APP_STORE
    import Foundation
    import LocalAuthentication
    import Security

    @MainActor
    protocol UpdateTokenStore {
        func readToken() throws -> String?
        func saveToken(_ token: String) throws
    }

    enum PrivateUpdateAccess {
        enum AccessError: LocalizedError {
            case missingToken, invalidToken, keychain(OSStatus)

            var errorDescription: String? {
                switch self {
                case .missingToken:
                    "Configure a GitHub token in Updates → Private Update Access… to download private updates."
                case .invalidToken:
                    "Enter a GitHub personal access token without spaces or line breaks."
                case let .keychain(status):
                    "Could not access the update token in Keychain (\(status))."
                }
            }
        }

        static func validToken(_ token: String) -> Bool {
            !token.isEmpty && token.utf8.allSatisfy {
                (65 ... 90).contains($0) || (97 ... 122).contains($0) || (48 ... 57).contains($0) || $0 == 95
            }
        }
    }

    @MainActor
    final class KeychainUpdateTokenStore: UpdateTokenStore {
        private var query: [String: Any] {
            [kSecClass as String: kSecClassGenericPassword,
             kSecAttrService as String: "\(Bundle.main.bundleIdentifier ?? "private-app").private-updates",
             kSecAttrAccount as String: "github-token",
             kSecAttrSynchronizable as String: false]
        }

        func readToken() throws -> String? {
            var request = query
            request[kSecReturnData as String] = true
            request[kSecMatchLimit as String] = kSecMatchLimitOne
            let context = LAContext()
            context.interactionNotAllowed = true
            request[kSecUseAuthenticationContext as String] = context
            var result: CFTypeRef?
            let status = SecItemCopyMatching(request as CFDictionary, &result)
            if status == errSecItemNotFound {
                return nil
            }
            guard status == errSecSuccess else { throw PrivateUpdateAccess.AccessError.keychain(status) }
            guard let data = result as? Data, let token = String(data: data, encoding: .utf8),
                  PrivateUpdateAccess.validToken(token) else { throw PrivateUpdateAccess.AccessError.invalidToken }
            return token
        }

        func saveToken(_ token: String) throws {
            guard PrivateUpdateAccess.validToken(token) else { throw PrivateUpdateAccess.AccessError.invalidToken }
            let value = [kSecValueData as String: Data(token.utf8)]
            var status = SecItemUpdate(query as CFDictionary, value as CFDictionary)
            if status == errSecItemNotFound {
                var item = query.merging(value) { _, new in new }
                item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                status = SecItemAdd(item as CFDictionary, nil)
            }
            guard status == errSecSuccess else { throw PrivateUpdateAccess.AccessError.keychain(status) }
        }
    }
#endif
