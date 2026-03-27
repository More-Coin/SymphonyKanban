import Foundation

struct LinearIssueTrackerResponseModel: Decodable {
    struct DataModel: Decodable {
        let issues: IssueConnectionModel?
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

private extension LinearIssueNodeModel {
    func normalizedRequired(_ value: String?, field: String) -> String? {
        guard let value = normalizedOptional(value) else {
            return nil
        }

        return value
    }

    func normalizedOptional(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }

    func normalizedDate(
        _ value: String?,
        field: String
    ) throws -> Date? {
        guard let value = normalizedOptional(value) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()

        guard let date = formatter.date(from: value) else {
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
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}
