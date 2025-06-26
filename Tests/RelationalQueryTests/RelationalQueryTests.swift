import Foundation
import XCTest
@testable import RelationalQuery

final class LinkTests: XCTestCase {
    
    func testQueryConstruction1() {
        
        let checkSurnameEndForD = true
        
        let query = RelationalQuery(
            table: "person",
            fields: [.renaming("name", to: "surname"), .field("prename")],
            condition: one {
                compare(field: "prename", withValue: "Bert")
                compare(field: "prename", withTemplate: "C*", wildcard: "*")
                all {
                    compare(field: "name", withPotentialTemplate: "D*", usingWildcard: "*")
                    if checkSurnameEndForD {
                        compare(field: "name", withPotentialTemplate: "*n", usingWildcard: "*")
                    }
                    compare(field: "prename", withPotentialTemplate: "Ernie", usingWildcard: "*")
                }
            },
            orderBy: [.field("name"), .withDirection("prename", .descending)]
        )
        
        XCTAssertEqual(
            query.sql,
            #"SELECT "name" AS "surname","prename" FROM "person" WHERE ("prename"='Bert' OR "prename" LIKE 'C%' OR ("name" LIKE 'D%' AND "name" LIKE '%n' AND "prename"='Ernie')) ORDER BY "name","prename" DESC"#
        )
        
        XCTAssertEqual(
            query.postgrest,
            #"person?select=surname:name,prename&or=(prename.eq.Bert,prename.like.C*,and=(name.like.D*,name.like.*n,prename.eq.Ernie))&order=name,prename.desc"#
        )
    }
    
}