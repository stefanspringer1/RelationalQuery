# RelationalQuery

This [Swift](https://www.swift.org/) library allows to construct relational database queries of a simple form in an abstract way with output to various formats, and for the same abstractly defined queries to formulate test in a simple way without using a "real" database.

This library is published under the Apache License v2.0 with Runtime Library Exception.

## Abstract queries

Example:

```swift
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

print("SQL:\n")
print(query.sql)

print("\nPostgREST:\n")
print(query.postgrest)
```

Result:

```text
SQL:
SELECT "name" AS "surname","prename" FROM "person" WHERE ("prename"='Bert' OR "prename" LIKE 'C%' OR ("name" LIKE 'D%' AND "name" LIKE '%n' AND "prename"='Ernie')) ORDER BY "name","prename" DESC

PostgREST:
person?select=surname:name,prename&or=(prename.eq.Bert,prename.like.C*,and=(name.like.D*,name.like.*n,prename.eq.Ernie))&order=name,prename.desc
```

New output formats can easily be added, see the extensions for `SQLConvertible` and `PostgRESTConvertible`.

## Tests

For testing a query, a simple test database (with values only as text) can be formulated as follows:

```swift
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
```

With e.g. the following an abstract query:

```swift
let query = RelationalQuery(
    table: "person",
    fields: [.renaming("name", to: "surname"), .field("prename")],
    condition: one {
        compare(field: "prename", withTemplate: "*o*", wildcard: "*")
        compare(field: "name", withTemplate: "*o*", wildcard: "*")
    },
    orderBy: [.field("name"), .fieldWithDirection("prename", .descending)]
)
```

We can apply the query to our test database and print the result as follows:

```swift
let result = query.excute(forTestDatabase: testDB)
print(result)
```

(In a unit test, compare `result.description` to the expected text.)

The following is then printed:

```text
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
```
