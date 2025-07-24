
public protocol RelationalQueryExecuter<Row> {
    associatedtype Row
    func exectute(query: RelationalQuery) -> [Row]
}
