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
                compare(field: "prename", withTemplate: "C*", usingWildcard: "*")
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
            #"person?select=surname:name,prename&or=(prename.eq.Bert,prename.like.C*,and(name.like.D*,name.like.*n,prename.eq.Ernie))&order=name,prename.desc"#
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
            "person": (
                ["prename", "name"],
                [
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
            )
        ]
        
        let query = RelationalQuery(
            table: "person",
            fields: [.renaming("name", to: "surname"), .field("prename")],
            condition: one {
                compare(field: "prename", withTemplate: "*o*", usingWildcard: "*")
                compare(field: "name", withTemplate: "*o*", usingWildcard: "*")
            },
            orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
        )
        
        let result = query.execute(forTestDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
            surname   | prename 
            ----------|---------
            Allison   | Atticus 
            Allison   | Atticus 
            Beltran   | Edison  
            Hodges    | Taylor  
            Hodges    | Emma    
            Holland   | Marleigh
            Johnson   | Ahmad   
            Mejia     | Loretta 
            Portillo  | Kaydence
            Portillo  | Gwen    
            Schneider | Loretta 
            Todd      | Wallace 
            """
        )
    }
    
}