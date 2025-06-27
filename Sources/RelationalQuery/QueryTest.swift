public typealias RelationalQueryTestDBRow = [String:String]
public typealias RelationalQueryTestDB = [String:[RelationalQueryTestDBRow]]
public typealias RelationalQueryTestResultRow = [(String,String?)]

public struct RelationalQueryTestResult: CustomStringConvertible {
    let rows: [RelationalQueryTestResultRow]
    
    public init(withRows rows: [RelationalQueryTestResultRow] = [RelationalQueryTestResultRow]()) {
        self.rows = rows
    }
    
    public var description: String {
        var lines = [String]()
        lines.append("[")
        for row in rows {
            lines.append("    [" + row.map{ "\($0.0): \($0.1?.prepending("\"").appending("\"") ?? "null")" }.joined(separator: ", ") + "]")
        }
        lines.append("]")
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
            value1 = row1[name]; value2 = row1[name]
            orderFactor = 1
        case .fieldWithDirection(let name, let direction):
            value1 = row1[name]; value2 = row1[name]
            orderFactor = switch direction {
            case .ascending: 1
            case .descending: -1
            }
        }
        guard let value1, let value2 else { return 0 }
        if value1 == value2 {
            return 0
        } else if value1 < value2 {
            return orderFactor
        } else {
            return -orderFactor
        }
    }
    
}

public extension RelationalQuery {
    
    func excute(forTestDatabase testDB: RelationalQueryTestDB) -> RelationalQueryTestResult {
        guard let allRows = testDB[self.table] else { return RelationalQueryTestResult() }
        var filteredAndSorted: [RelationalQueryTestDBRow]
        if let condition = self.condition {
            filteredAndSorted = allRows.filter { condition.check(row: $0) }
        } else {
            filteredAndSorted = allRows
        }
        if let order = self.order {
            filteredAndSorted.sort { row1, row2 in
                order.lazy.map { $0.compare(row1, with: row2) }.filter{ $0 != 0 }.first != 1
            }
        }
        var result = [RelationalQueryTestResultRow]()
        if let fields {
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryTestResultRow()
                for field in fields {
                    switch field {
                    case .field(let name):
                        newRow.append((name,originalRow[name]))
                    case .renaming(let name, to: let newName):
                        newRow.append((newName,originalRow[name]))
                    }
                }
                result.append(newRow)
            }
        } else {
            for originalRow in filteredAndSorted {
                var newRow = RelationalQueryTestResultRow()
                for (field, value) in originalRow.sorted(by: { $0.key < $1.key }) {
                    newRow.append((field, value))
                }
                result.append(newRow)
            } 
        }
        return RelationalQueryTestResult(withRows: result)
    }
    
}
