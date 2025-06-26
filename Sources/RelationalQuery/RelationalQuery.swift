import Foundation

public enum RelationalField {
    case field(_ name: String)
    case renaming(_ name: String, to: String)
}

public enum RelationalQueryOrderDirection {
    case ascending
    case descending
}

public enum RelationalQueryResultOrder {
    case field(_ name: String)
    case withDirection(_ name: String, _ direction: RelationalQueryOrderDirection)
}

public indirect enum RelationalQueryCondition {
    case equal(field: String, value: String)
    case similar(field: String, template: String, wildcard: String)
    case and(_ conditions: [RelationalQueryCondition])
    case or(_ conditions: [RelationalQueryCondition])
}

public func compare(field: String, withValue value: String) -> RelationalQueryCondition {
    .equal(field: field, value: value)
}

public func compare(field: String, withTemplate template: String, wildcard: String) -> RelationalQueryCondition {
    .similar(field: field, template: template, wildcard: wildcard)
}

/// If the "possible template" contains at least one wildcard, it will be used for a "similarity" commparison, else th result is a equality comparison.
public func compare(field: String, withPotentialTemplate potentialTemplate: String, usingWildcard wildcard: String) -> RelationalQueryCondition {
    if potentialTemplate.contains(wildcard) {
        .similar(field: field, template: potentialTemplate, wildcard: wildcard)
    } else {
        .equal(field: field, value: potentialTemplate)
    }
}

public struct RelationalQuery {
    
    public let table: String
    public let fields: [RelationalField]? // if not set, get all fields
    public let condition: RelationalQueryCondition?
    public let order: [RelationalQueryResultOrder]?
    
    public init(
        table: String,
        fields: [RelationalField]? = nil, // if not set, get all fields
        condition: RelationalQueryCondition? = nil,
        orderBy order: [RelationalQueryResultOrder]? = nil,
    ) {
        self.table = table
        self.fields = fields
        self.order = order
        self.condition = condition
    }
    
}
