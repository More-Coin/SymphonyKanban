import Foundation
import Testing
@testable import SymphonyKanban

struct SymphonyAuthCallbackParsingTests {
    @Test
    func parsesHostBackedKindAndOAuthFields() throws {
        let callbackURL = try #require(
            URL(string: "symphony://linear?code=abc123&state=xyz&error_description=none")
        )

        let callback = try SymphonyTrackerAuthCallbackDTO(
            callbackURL: callbackURL
        ).callbackContract(trackerKind: "linear")

        #expect(callback.trackerKind == "linear")
        #expect(callback.authorizationCode == "abc123")
        #expect(callback.state == "xyz")
        #expect(callback.errorDescription == "none")
    }

    @Test
    func rejectsURLsWithoutKindContext() throws {
        let callbackURL = try #require(
            URL(string: "symphony:?code=abc123")
        )

        #expect(throws: SymphonyTrackerAuthPresentationError.self) {
            _ = try SymphonyTrackerAuthCallbackDTO(
                callbackURL: callbackURL
            ).callbackContract(trackerKind: "")
        }
    }
}
