import Foundation

public enum RelationalQueryTestDBDataType {
    case TEXT
    case INTEGER
    case BOOLEAN
}

public enum RelationalQueryTestDBValue: CustomStringConvertible, Decodable {
    case text(_: String)
    case integer(_: Int)
    case boolean(_: Bool)
    
    public var description: String {
        switch self {
        case .text(let value): value
        case .integer(let value): value.description
        case .boolean(let value): value.description
        }
    }
}

public typealias RelationalQueryTestDBFieldDefinitions = [String:RelationalQueryTestDBDataType]
public typealias RelationalQueryTestDBRow = [String:RelationalQueryTestDBValue]
public typealias RelationalQueryTestTable = (RelationalQueryTestDBFieldDefinitions,[RelationalQueryTestDBRow])
public typealias RelationalQueryTestDB = [String:RelationalQueryTestTable]
public typealias RelationalQueryTestResultRow = [String:RelationalQueryTestDBValue]

public struct RelationalQueryTestResult: CustomStringConvertible {
    public let fields: [String]
    public let rows: [RelationalQueryTestResultRow]
    public let displayedColumnWith: [String:Int]
    
    public init(fields: [String], withRows rows: [RelationalQueryTestResultRow] = [RelationalQueryTestResultRow]()) {
        self.fields = fields
        self.rows = rows
        var displayedColumnWith = [String:Int]()
        for field in fields {
            displayedColumnWith[field] = field.count
            for row in rows {
                if let length = row[field]?.description.count, length > displayedColumnWith[field] ?? 0 {
                    displayedColumnWith[field] = length
                }
            }
        }
        self.displayedColumnWith = displayedColumnWith
    }
    
    public var description: String {
        
        func extending(_ s: String, toLength length: Int) -> String {
            let diff = length - s.count
            if diff <= 0 {
                return s
            } else {
                return s + String(repeating: " ", count: diff)
            }
        }
        
        var lines = [String]()
        lines.append(fields.map{ extending($0, toLength: displayedColumnWith[$0] ?? 0) }.joined(separator: " | "))
        lines.append(fields.map{ String(repeating: "-", count: (displayedColumnWith[$0] ?? 0)) }.joined(separator: "-|-"))
        for row in rows {
            lines.append(fields.map{ extending(row[$0]?.description ?? "", toLength: displayedColumnWith[$0] ?? 0) }.joined(separator: " | "))
        }
        return lines.joined(separator: "\n")
    }
}

public extension RelationalQueryCondition {
    
    func check(row: RelationalQueryTestDBRow) -> Bool {
        switch self {
        case .equalText(field: let field, value: let value):
            guard case .text(let text) = row[field] else { return false}
            return text == value
        case .equalInteger(field: let field, value: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text == value
        case .smallerInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text < value
        case .smallerOrEqualInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text <= value
        case .greaterInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text > value
        case .greaterOrEqualInteger(field: let field, than: let value):
            guard case .integer(let text) = row[field] else { return false}
            return text >= value
        case .equalBoolean(field: let field, value: let value):
            guard case .boolean(let text) = row[field] else { return false}
            return text == value
        case .similarText(field: let field, template: let template, wildcard: let wildcard):
            do {
                guard case .text(let text) = row[field] else { return false}
                let regex = try Regex("^\(template.replacing(wildcard, with: ".*"))$")
                return text.contains(regex)
            } catch {
                return false
            }
        case .not(let condition):
            return !condition.check(row: row)
        case .and(let conditions):
            for condition in conditions {
                if !condition.check(row: row) {
                    return false
                }
            }
            return true
        case .or(let conditions):
            for condition in conditions {
                if condition.check(row: row) {
                    return true
                }
            }
            return false
        }
    }
    
}

public extension RelationalQueryResultOrder {
    
    func compare(_ row1: RelationalQueryTestDBRow, with row2: RelationalQueryTestDBRow) -> Int {
        var value1: String? = nil
        var value2: String? = nil
        let orderFactor: Int
        switch self {
        case .field(let name):
            if case .text(let text) = row1[name] { value1 = text }
            if case .text(let text) = row2[name] { value2 = text }
            orderFactor = 1
        case .fieldWithDirection(let name, let direction):
            if case .text(let text) = row1[name] { value1 = text }
            if case .text(let text) = row2[name] { value2 = text }
            orderFactor = switch direction {
            case .ascending: 1
            case .descending: -1
            }
        }
        guard let value1, let value2 else { return 0 }
        if value1 == value2 {
            return 0
        } else if value1 < value2 {
            return -orderFactor
        } else {
            return orderFactor
        }
    }
    
}

public extension RelationalQuery {
    
    func execute(forTestDatabase testDB: RelationalQueryTestDB) -> RelationalQueryTestResult {
        guard let (orinalFieldNames,allRows) = testDB[self.table] else { return RelationalQueryTestResult(fields: [String]()) }
        var filteredAndSorted: [RelationalQueryTestDBRow]
        if let condition = self.condition {
            filteredAndSorted = allRows.filter { condition.check(row: $0) }
        } else {
            filteredAndSorted = allRows
        }
        if let order = self.order {
            filteredAndSorted.sort { row1, row2 in
                return order.lazy.map { $0.compare(row1, with: row2) }.filter{ $0 != 0 }.first != 1
            }
        }
        var result = [RelationalQueryTestResultRow]()
        let fieldNames: [String]
        if let fields {
            do {
                var newFieldNames = [String]()
                for field in fields {
                    switch field {
                    case .field(let name):
                        newFieldNames.append(name)
                    case .renaming(_, to: let newName):
                        newFieldNames.append(newName)
                    }
                }
                fieldNames = newFieldNames
            }
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryTestResultRow()
                for field in fields {
                    switch field {
                    case .field(let name):
                        newRow[name] = originalRow[name]
                    case .renaming(let name, to: let newName):
                        newRow[newName] = originalRow[name]
                    }
                }
                result.append(newRow)
            }
        } else {
            fieldNames = orinalFieldNames.map { $0.0 }
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryTestResultRow()
                for (field, value) in originalRow.sorted(by: { $0.key < $1.key }) {
                    newRow[field] = value
                }
                result.append(newRow)
            } 
        }
        return RelationalQueryTestResult(fields: fieldNames, withRows: result)
    }
    
}

public func relationalQueryTestDBTable(
    withFieldsDefinitions fieldsDefinitions: RelationalQueryTestDBFieldDefinitions,
    fromGenericValues genericRows: [[String:Any]]
) throws -> RelationalQueryTestTable {
    var rows = [RelationalQueryTestDBRow]()
    for genericRow in genericRows {
        var row = RelationalQueryTestDBRow()
        for (key,value) in genericRow {
            if let text = value as? String { row[key] = .text(text) }
            else if let int = value as? Int {
                if fieldsDefinitions[key] == .BOOLEAN {
                    row[key] = .boolean(int != 0)
                } else {
                    row[key] = .integer(int)
                }
            }
            else if let bool = value as? Bool { row[key] = .boolean(bool) }
            else { throw RelationalQueryError("invalid value: \(value)") }
        }
        rows.append(row)
    }
    return (fieldsDefinitions, rows)
}

public func relationalQueryTestTable(
    withFieldsDefinitions fieldsDefinitions: RelationalQueryTestDBFieldDefinitions,
    fromJSON json: String
) throws -> RelationalQueryTestTable {
    guard let jsonData = json.data(using: .utf8) else { throw RelationalQueryError("could not convert JSON string to Data") }
    let json = try JSONSerialization.jsonObject(with: jsonData)
    guard let genericRows = json as? [[String: Any]] else { throw RelationalQueryError("JSON has wrong structure") }
    return try relationalQueryTestDBTable(withFieldsDefinitions: fieldsDefinitions, fromGenericValues: genericRows)
}
