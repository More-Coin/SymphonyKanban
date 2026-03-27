import Foundation

public protocol SourceFileDiscoveryPortProtocol {
    func discoverSwiftFiles(in rootURL: URL) throws -> [URL]
}
