public protocol SQLConvertible {
    var sql: String { get }
}

extension RelationalField: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .field(let name):
            name.asSQLName
        case .renaming(let name, to: let newName):
            name.asSQLName + " AS " + newName.asSQLName
        }
    }
    
}

extension RelationalQueryOrderDirection: SQLConvertible {

    public var sql: String {
        switch self {
            case .ascending:
            "ASC"
            case .descending:
            "DESC"
        }
    }
    
}

extension RelationalQueryResultOrder: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .field(let name):
            name.asSQLName
        case .fieldWithDirection(let name, let direction):
            "\(name.asSQLName) \(direction.sql)"
        }
    }
    
}

extension RelationalQueryCondition: SQLConvertible {
    
    public var sql: String {
        switch self {
        case .equal(let field, let value):
            field.asSQLName + "=" + value.asSQLText
        case .similar(field: let field, template: let template, wildcard: let wildcard):
            field.asSQLName + " LIKE " + template.replacing(wildcard, with: "%").asSQLText
        case .and(let conditions):
            "(" + conditions.map{ $0.sql }.joined(separator: " AND ") + ")"
        case .or(let conditions):
            "(" + conditions.map{ $0.sql }.joined(separator: " OR ") + ")"
        }
    }
    
}

extension RelationalQuery: SQLConvertible {
    
    public var sql: String {
        var result = "SELECT \(fields?.map{ $0.sql }.joined(separator: ",") ?? "*") FROM \(table.asSQLName)"
        if let condition {
            result += " WHERE " + condition.sql
        }
        if let order {
            result += " ORDER BY " + order.map{ $0.sql }.joined(separator: ",")
        }
        return result
    }
    
}
