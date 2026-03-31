import Foundation

struct LinearIssueTrackerResponseModel: Decodable {
    struct DataModel: Decodable {
        let issues: IssueConnectionModel?
        let teams: LinearTeamConnectionModel?
        let projects: LinearProjectConnectionModel?
    }

    struct GraphQLErrorModel: Decodable {
        let message: String?
    }

    let data: DataModel?
    let errors: [GraphQLErrorModel]?
}

struct IssueConnectionModel: Decodable {
    let nodes: [LinearIssueNodeModel]?
    let pageInfo: LinearPageInfoModel?
}

struct LinearPageInfoModel: Decodable {
    let hasNextPage: Bool?
    let endCursor: String?
}

struct LinearTeamConnectionModel: Decodable {
    let nodes: [LinearTeamNodeModel]?
}

struct LinearTeamNodeModel: Decodable {
    let id: String?
    let name: String?
    let key: String?

    func toDomain() throws -> SymphonyTrackerScopeOptionContract {
        guard let id = normalizedRequired(id),
              let name = normalizedRequired(name) else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The team payload was missing one or more required fields."
            )
        }

        let normalizedKey = linearNormalizedOptional(key)

        return SymphonyTrackerScopeOptionContract(
            id: "team:\(id)",
            scopeKind: "team",
            scopeIdentifier: id,
            scopeName: name,
            detailText: normalizedKey.map { "Team key \($0)" }
        )
    }
}

struct LinearProjectConnectionModel: Decodable {
    let nodes: [LinearProjectNodeModel]?
    let pageInfo: LinearPageInfoModel?
}

struct LinearProjectNodeModel: Decodable {
    let id: String?
    let name: String?
    let slugId: String?
    let state: String?
    let teams: LinearTeamConnectionModel?

    func toDomain() throws -> SymphonyTrackerScopeOptionContract {
        guard let id = normalizedRequired(id),
              let name = normalizedRequired(name) else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The project payload was missing one or more required fields."
            )
        }

        let persistedIdentifier = linearNormalizedOptional(slugId) ?? id
        let teamNames = (teams?.nodes ?? [])
            .compactMap { linearNormalizedOptional($0.name) }
        let stateText = linearNormalizedOptional(state)
        let subtitleParts = [
            stateText,
            teamNames.isEmpty ? nil : teamNames.joined(separator: ", ")
        ]
        .compactMap { $0 }

        return SymphonyTrackerScopeOptionContract(
            id: "project:\(persistedIdentifier)",
            scopeKind: "project",
            scopeIdentifier: persistedIdentifier,
            scopeName: name,
            detailText: subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: " • ")
        )
    }
}

struct LinearIssueNodeModel: Decodable {
    let id: String?
    let identifier: String?
    let title: String?
    let description: String?
    let priority: LinearPriorityValueModel?
    let state: LinearIssueStateModel?
    let branchName: String?
    let url: String?
    let labels: LinearLabelConnectionModel?
    let inverseRelations: LinearIssueRelationConnectionModel?
    let createdAt: String?
    let updatedAt: String?

    func toDomain() throws -> SymphonyIssue {
        guard let id = normalizedRequired(id, field: "id"),
              let identifier = normalizedRequired(identifier, field: "identifier"),
              let title = normalizedRequired(title, field: "title"),
              let state = normalizedRequired(state?.name, field: "state.name"),
              let stateType = normalizedRequired(self.state?.type, field: "state.type") else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The issue payload was missing one or more required fields."
            )
        }

        return SymphonyIssue(
            id: id,
            identifier: identifier,
            title: title,
            description: normalizedOptional(description),
            priority: priority?.integerValue,
            state: state,
            stateType: stateType,
            branchName: normalizedOptional(branchName),
            url: normalizedOptional(url),
            labels: (labels?.nodes ?? []).compactMap { normalizedOptional($0.name) },
            blockedBy: inverseRelations?.toDomain() ?? [],
            createdAt: try normalizedDate(createdAt, field: "createdAt"),
            updatedAt: try normalizedDate(updatedAt, field: "updatedAt")
        )
    }
}

struct LinearPriorityValueModel: Decodable {
    let integerValue: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        integerValue = try? container.decode(Int.self)
    }
}

struct LinearIssueStateModel: Decodable {
    let name: String?
    let type: String?
}

struct LinearLabelConnectionModel: Decodable {
    let nodes: [LinearLabelNodeModel]?
}

struct LinearLabelNodeModel: Decodable {
    let name: String?
}

struct LinearIssueRelationConnectionModel: Decodable {
    let nodes: [LinearIssueRelationNodeModel]?

    func toDomain() -> [SymphonyIssueBlockerReference] {
        (nodes ?? []).compactMap { $0.toDomain() }
    }
}

struct LinearIssueRelationNodeModel: Decodable {
    let type: String?
    let relatedIssue: LinearRelatedIssueNodeModel?
}

struct LinearRelatedIssueNodeModel: Decodable {
    let id: String?
    let identifier: String?
    let state: LinearIssueStateModel?
}

private func normalizedRequired(
    _ value: String?
) -> String? {
    guard let value = linearNormalizedOptional(value) else {
        return nil
    }

    return value
}

private func linearNormalizedOptional(
    _ value: String?
) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty else {
        return nil
    }

    return value
}

private enum LinearIssueTimestampParser {
    static func internetDateTimeFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    static func fractionalSecondFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static func date(from value: String) -> Date? {
        fractionalSecondFormatter().date(from: value)
            ?? internetDateTimeFormatter().date(from: value)
    }
}

private extension LinearIssueNodeModel {
    func normalizedRequired(_ value: String?, field: String) -> String? {
        guard let value = linearNormalizedOptional(value) else {
            return nil
        }

        return value
    }

    func normalizedOptional(_ value: String?) -> String? {
        linearNormalizedOptional(value)
    }

    func normalizedDate(
        _ value: String?,
        field: String
    ) throws -> Date? {
        guard let value = normalizedOptional(value) else {
            return nil
        }

        guard let date = LinearIssueTimestampParser.date(from: value) else {
            throw SymphonyIssueTrackerInfrastructureError.linearUnknownPayload(
                details: "The issue payload contained an invalid ISO-8601 timestamp for `\(field)`."
            )
        }

        return date
    }
}

private extension LinearIssueRelationNodeModel {
    func toDomain() -> SymphonyIssueBlockerReference? {
        guard type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "blocks" else {
            return nil
        }

        return SymphonyIssueBlockerReference(
            id: normalizedOptional(relatedIssue?.id),
            identifier: normalizedOptional(relatedIssue?.identifier),
            state: normalizedOptional(relatedIssue?.state?.name),
            stateType: normalizedOptional(relatedIssue?.state?.type)
        )
    }

    func normalizedOptional(_ value: String?) -> String? {
        linearNormalizedOptional(value)
    }
}
