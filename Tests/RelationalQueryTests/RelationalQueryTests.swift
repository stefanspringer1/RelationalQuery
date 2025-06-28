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
                compare(textField: "prename", withValue: "Bert")
                compare(textField: "prename", withTemplate: "C*", usingWildcard: "*")
                all {
                    compare(textField: "name", withPotentialTemplate: "D*", usingWildcard: "*")
                    if checkSurnameEndForD {
                        compare(textField: "name", withPotentialTemplate: "*n", usingWildcard: "*")
                    }
                    compare(textField: "prename", withPotentialTemplate: "Ernie", usingWildcard: "*")
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
        
        let row1: RelationalQueryDBRow = ["prename": .text("Wallace"), "name": .text("Portillo")]
        let row2: RelationalQueryDBRow = ["prename": .text("Gwen"), "name": .text("Todd")]
        
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
        
        let testDB: RelationalQueryDB = [
            "person": try relationalQueryDBTable(
                withFieldsDefinitions: ["prename": .TEXT, "name": .TEXT, "age": .INTEGER, "member": .BOOLEAN],
                fromGenericValues:
                [
                    ["prename": "Gwen", "name": "Portillo", "age": 45, "member": false],
                    ["prename": "Wallace", "name": "Todd", "age": 27, "member": false],
                    ["prename": "Zariah", "name": "Curtis", "age": 63, "member": false],
                    ["prename": "Muhammad", "name": "Avery", "age": 33, "member": true],
                    ["prename": "Ahmad", "name": "Johnson", "age": 26, "member": true],
                    ["prename": "Taylor", "name": "Hodges", "age": 21, "member": false],
                    ["prename": "Emma", "name": "Hodges", "age": 55, "member": false],
                    ["prename": "Kaydence", "name": "McClain", "age": 37, "member": false],
                    ["prename": "Marleigh", "name": "Holland", "age": 40, "member": true],
                    ["prename": "Brady", "name": "Brandt", "age": 34, "member": false],
                    ["prename": "Loretta", "name": "Mejia", "age": 51, "member": false],
                    ["prename": "Alayah", "name": "McGee", "age": 66, "member": false],
                    ["prename": "Wallace", "name": "Weber", "age": 44, "member": true],
                    ["prename": "Loretta", "name": "Schneider", "age": 23, "member": false],
                    ["prename": "Alayah", "name": "McGee", "age": 23, "member": false],
                    ["prename": "Atticus", "name": "Allison", "age": 50, "member": true],
                    ["prename": "Edison", "name": "Beltran", "age": 49, "member": false],
                    ["prename": "Atticus", "name": "Allison", "age": 47, "member": true],
                    ["prename": "Kaydence", "name": "Portillo", "age": 30, "member": false],
                ]
            )
        ]
        
        let query = RelationalQuery(
            table: "person",
            fields: [.renaming("name", to: "surname"), .field("prename"), .field("age"), .field("member")],
            condition: one {
                compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
                compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
            },
            orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
        )
        
        let result = query.execute(forDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
            surname   | prename  | age | member
            ----------|----------|-----|-------
            Allison   | Atticus  | 47  | true  
            Allison   | Atticus  | 50  | true  
            Beltran   | Edison   | 49  | false 
            Hodges    | Taylor   | 21  | false 
            Hodges    | Emma     | 55  | false 
            Holland   | Marleigh | 40  | true  
            Johnson   | Ahmad    | 26  | true  
            Mejia     | Loretta  | 51  | false 
            Portillo  | Kaydence | 30  | false 
            Portillo  | Gwen     | 45  | false 
            Schneider | Loretta  | 23  | false 
            Todd      | Wallace  | 27  | false 
            """
        )
    }
    
    func testQueryTestWithJSON() throws {
        
        let testDB: RelationalQueryDB = [
            "person": try relationalQueryDBTable(
                withFieldsDefinitions: ["prename": .TEXT, "name": .TEXT, "age": .INTEGER, "member": .BOOLEAN],
                fromJSON: """
                [
                    {"prename": "Gwen", "name": "Portillo", "age": 45, "member": false},
                    {"prename": "Wallace", "name": "Todd", "age": 27, "member": false}, 
                    {"prename": "Zariah", "name": "Curtis", "age": 63, "member": false}, 
                    {"prename": "Muhammad", "name": "Avery", "age": 33, "member": true}, 
                    {"prename": "Ahmad", "name": "Johnson", "age": 26, "member": true}, 
                    {"prename": "Taylor", "name": "Hodges", "age": 21, "member": false},
                    {"prename": "Emma", "name": "Hodges", "age": 55, "member": false}, 
                    {"prename": "Kaydence", "name": "McClain", "age": 37, "member": false}, 
                    {"prename": "Marleigh", "name": "Holland", "age": 40, "member": true}, 
                    {"prename": "Brady", "name": "Brandt", "age": 34, "member": false}, 
                    {"prename": "Loretta", "name": "Mejia", "age": 51, "member": false}, 
                    {"prename": "Alayah", "name": "McGee", "age": 66, "member": false}, 
                    {"prename": "Wallace", "name": "Weber", "age": 44, "member": true}, 
                    {"prename": "Loretta", "name": "Schneider", "age": 23, "member": false}, 
                    {"prename": "Alayah", "name": "McGee", "age": 23, "member": false}, 
                    {"prename": "Atticus", "name": "Allison", "age": 50, "member": true}, 
                    {"prename": "Edison", "name": "Beltran", "age": 49, "member": false}, 
                    {"prename": "Atticus", "name": "Allison", "age": 47, "member": true}, 
                    {"prename": "Kaydence", "name": "Portillo", "age": 30, "member": false}
                ]
                """
            )
        ]
        
        let query = RelationalQuery(
            table: "person",
            fields: [.renaming("name", to: "surname"), .field("prename"), .field("age"), .field("member")],
            condition: one {
                compare(textField: "prename", withTemplate: "*o*", usingWildcard: "*")
                compare(textField: "name", withTemplate: "*o*", usingWildcard: "*")
            },
            orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
        )
        
        let result = query.execute(forDatabase: testDB)
        
        XCTAssertEqual(
            result.description,
            """
            surname   | prename  | age | member
            ----------|----------|-----|-------
            Allison   | Atticus  | 47  | true  
            Allison   | Atticus  | 50  | true  
            Beltran   | Edison   | 49  | false 
            Hodges    | Taylor   | 21  | false 
            Hodges    | Emma     | 55  | false 
            Holland   | Marleigh | 40  | true  
            Johnson   | Ahmad    | 26  | true  
            Mejia     | Loretta  | 51  | false 
            Portillo  | Kaydence | 30  | false 
            Portillo  | Gwen     | 45  | false 
            Schneider | Loretta  | 23  | false 
            Todd      | Wallace  | 27  | false 
            """
        )
    }
    
}
