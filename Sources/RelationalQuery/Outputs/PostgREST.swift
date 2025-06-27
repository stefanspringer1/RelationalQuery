public protocol PostgRESTConvertible {
    var postgrest: String { get }
}

extension RelationalField: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
        case .field(let name):
            name.urlEscaped
        case .renaming(let name, to: let newName):
            newName.urlEscaped + ":" + name.urlEscaped
        }
    }
    
}

extension RelationalQueryOrderDirection: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
            case .ascending:
            "asc"
            case .descending:
            "desc"
        }
    }
}

extension RelationalQueryResultOrder: PostgRESTConvertible {
    
    public var postgrest: String {
        switch self {
        case .field(let name):
            name.urlEscaped
        case .fieldWithDirection(let name, let direction):
            "\(name.urlEscaped).\(direction.postgrest)"
        }
    }
    
}

extension RelationalQueryCondition: PostgRESTConvertible {
    
    public var postgrest: String {
        postgrest(topLevel: true)
    }
    
    public func postgrest(topLevel: Bool) -> String {
        switch self {
        case .equal(let field, let value):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")eq.\(value.urlEscaped)"
        case .similar(field: let field, template: let value, wildcard: let wildcard):
            "\(field.urlEscaped)\(topLevel ? "=" : ".")like.\(value.replacing(wildcard, with: "*").urlEscaped)"
        case .and(let conditions):
            "and\(topLevel ? "=" : "")(\(conditions.map{ $0.postgrest(topLevel: false) }.joined(separator: ",")))"
        case .or(let conditions):
            "or\(topLevel ? "=" : "")(\(conditions.map{ $0.postgrest(topLevel: false) }.joined(separator: ",")))"
        }
    }
    
}

extension RelationalQuery: PostgRESTConvertible {
    
    public var postgrest: String {
        var result = "\(table.urlEscaped)?"
        var needsAmpersand = false
        if let fields {
            result += "select=" + fields.map{ $0.postgrest }.joined(separator: ",")
            needsAmpersand = true
        }
        if let condition {
            if needsAmpersand { result += "&" }
            result += condition.postgrest
            needsAmpersand = true
        }
        if let order {
            if needsAmpersand { result += "&"}
            result += order.map{ $0.postgrest }.joined(separator: ",").prepending("order=")
        }
        return result
    }
    
}