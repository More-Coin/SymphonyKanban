import Foundation

struct LinearOAuthRefreshDefinitionModel {
    func fromContract(
        from session: LinearOAuthSessionModel
    ) throws -> SymphonyTrackerOAuthRefreshContract {
        guard let refreshToken = session.refreshToken?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !refreshToken.isEmpty else {
            throw SymphonyIssueTrackerInfrastructureError.staleTrackerSession(
                details: "The stored Linear session expired and has no refresh token."
            )
        }

        return SymphonyTrackerOAuthRefreshContract(
            refreshToken: refreshToken
        )
    }
}
