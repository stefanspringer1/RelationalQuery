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
            orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
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
    
    func testQueryTestRowCompare() throws {
        
        let row1: RelationalQueryTestDBRow = ["prename": "Wallace", "name": "Portillo"]
        let row2: RelationalQueryTestDBRow = ["prename": "Gwen", "name": "Todd"]
        
        // sorting along "name":
        XCTAssertEqual(RelationalQueryResultOrder.field("prename").compare(row1, with: row2), 1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection("prename", .ascending).compare(row1, with: row2), 1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection("prename", .descending).compare(row1, with: row2), -1)
        
        // sorting along "prename":
        XCTAssertEqual(RelationalQueryResultOrder.field("name").compare(row1, with: row2), -1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection("name", .ascending).compare(row1, with: row2), -1)
        XCTAssertEqual(RelationalQueryResultOrder.fieldWithDirection("name", .descending).compare(row1, with: row2), 1)
    }
    
    func testQueryTest() throws {
        
        let testDB: RelationalQueryTestDB = [
            "person": [
                ["prename": "Gwen", "name": "Portillo"], 
                ["prename": "Wallace", "name": "Todd"], 
                ["prename": "Zariah", "name": "Curtis"], 
                ["prename": "Muhammad", "name": "Avery"], 
                ["prename": "Ahmad", "name": "Johnson"], 
                ["prename": "Taylor", "name": "Hodges"],
                ["prename": "Emma", "name": "Hodges"], 
                ["prename": "Kaydence", "name": "McClain"], 
                ["prename": "Marleigh", "name": "Holland"], 
                ["prename": "Brady", "name": "Brandt"], 
                ["prename": "Loretta", "name": "Mejia"], 
                ["prename": "Alayah", "name": "McGee"], 
                ["prename": "Wallace", "name": "Weber"], 
                ["prename": "Loretta", "name": "Schneider"], 
                ["prename": "Alayah", "name": "McGee"], 
                ["prename": "Atticus", "name": "Allison"], 
                ["prename": "Edison", "name": "Beltran"], 
                ["prename": "Atticus", "name": "Allison"], 
                ["prename": "Kaydence", "name": "Portillo"], 
            ]
        ]
        
        let query = RelationalQuery(
            table: "person",
            fields: [.renaming("name", to: "surname"), .field("prename")],
            condition: one {
                compare(field: "prename", withTemplate: "*o*", wildcard: "*")
                compare(field: "name", withTemplate: "*o*", wildcard: "*")
            },
            orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
        )
        
        let result = query.excute(forTestDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
            [
                (surname: "Allison", prename: "Atticus")
                (surname: "Allison", prename: "Atticus")
                (surname: "Beltran", prename: "Edison")
                (surname: "Hodges", prename: "Taylor")
                (surname: "Hodges", prename: "Emma")
                (surname: "Holland", prename: "Marleigh")
                (surname: "Johnson", prename: "Ahmad")
                (surname: "Mejia", prename: "Loretta")
                (surname: "Portillo", prename: "Kaydence")
                (surname: "Portillo", prename: "Gwen")
                (surname: "Schneider", prename: "Loretta")
                (surname: "Todd", prename: "Wallace")
            ]
            """
        )
    }
    
}