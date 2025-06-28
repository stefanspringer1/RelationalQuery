import Foundation

public typealias RelationalQueryTestDBFields = [String]
public typealias RelationalQueryTestDBRow = [String:String]
public typealias RelationalQueryTestDB = [String:(RelationalQueryTestDBFields,[RelationalQueryTestDBRow])]
public typealias RelationalQueryTestResultRow = [String:String]

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
                if let length = row[field]?.count, length > displayedColumnWith[field] ?? 0 {
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
            lines.append(fields.map{ extending(row[$0] ?? "", toLength: displayedColumnWith[$0] ?? 0) }.joined(separator: " | "))
        }
        return lines.joined(separator: "\n")
    }
}

public extension RelationalQueryCondition {
    
    func check(row: RelationalQueryTestDBRow) -> Bool {
        switch self {
        case .equal(field: let field, value: let value):
            return row[field] == value
        case .similar(field: let field, template: let template, wildcard: let wildcard):
            do {
                let regex = try Regex("^\(template.replacing(wildcard, with: ".*"))$")
                return row[field]?.contains(regex) == true
            } catch {
                return false
            }
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
        let value1: String?
        let value2: String?
        let orderFactor: Int
        switch self {
        case .field(let name):
            value1 = row1[name]
            value2 = row2[name]
            orderFactor = 1
        case .fieldWithDirection(let name, let direction):
            value1 = row1[name]
            value2 = row2[name]
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
            fieldNames = orinalFieldNames
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

public func relationalQueryTestDBRows(fromJSON json: String) throws -> [RelationalQueryTestDBRow] {
    guard let jsonData = json.data(using: .utf8) else { throw RelationalQueryError("could not convert JSON string to Data") }
    return try JSONDecoder().decode([RelationalQueryTestDBRow].self, from: jsonData)
}
