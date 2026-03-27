import Foundation
import Security

protocol LinearOAuthSecureStoreProtocol: Sendable {
    func loadSession() throws -> LinearOAuthSessionModel?
    func saveSession(_ session: LinearOAuthSessionModel) throws
    func clearSession() throws
    func loadPendingAuthorization() throws -> LinearOAuthPendingAuthorizationModel?
    func savePendingAuthorization(_ pendingAuthorization: LinearOAuthPendingAuthorizationModel) throws
    func clearPendingAuthorization() throws
}

struct LinearOAuthSecureStore: LinearOAuthSecureStoreProtocol {
    private let serviceName: String
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    init(
        serviceName: String = "com.symphonykanban.linear.oauth",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.serviceName = serviceName
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    func loadSession() throws -> LinearOAuthSessionModel? {
        try loadValue(account: "session", as: LinearOAuthSessionModel.self)
    }

    func saveSession(_ session: LinearOAuthSessionModel) throws {
        try saveValue(session, account: "session")
    }

    func clearSession() throws {
        try deleteValue(account: "session")
    }

    func loadPendingAuthorization() throws -> LinearOAuthPendingAuthorizationModel? {
        try loadValue(account: "pending_authorization", as: LinearOAuthPendingAuthorizationModel.self)
    }

    func savePendingAuthorization(_ pendingAuthorization: LinearOAuthPendingAuthorizationModel) throws {
        try saveValue(pendingAuthorization, account: "pending_authorization")
    }

    func clearPendingAuthorization() throws {
        try deleteValue(account: "pending_authorization")
    }

    private func loadValue<T: Decodable>(
        account: String,
        as _: T.Type
    ) throws -> T? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw secureStoreError("Keychain item for `\(account)` did not return Data.")
            }
            do {
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                throw secureStoreError(
                    "Keychain item for `\(account)` could not be decoded: \(error.localizedDescription)"
                )
            }
        case errSecItemNotFound:
            return nil
        default:
            throw secureStoreError(
                "Keychain lookup for `\(account)` failed with status \(status)."
            )
        }
    }

    private func saveValue<T: Encodable>(
        _ value: T,
        account: String
    ) throws {
        let data: Data
        do {
            data = try jsonEncoder.encode(value)
        } catch {
            throw secureStoreError(
                "Keychain payload for `\(account)` could not be encoded: \(error.localizedDescription)"
            )
        }

        let updateQuery = baseQuery(account: account)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw secureStoreError(
                "Keychain update for `\(account)` failed with status \(updateStatus)."
            )
        }

        var addQuery = baseQuery(account: account)
        addQuery[kSecValueData as String] = data

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw secureStoreError(
                "Keychain write for `\(account)` failed with status \(addStatus)."
            )
        }
    }

    private func deleteValue(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw secureStoreError(
                "Keychain delete for `\(account)` failed with status \(status)."
            )
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
    }

    private func secureStoreError(
        _ details: String
    ) -> SymphonyTrackerAuthInfrastructureError {
        .secureStoreFailure(details: details)
    }
}
