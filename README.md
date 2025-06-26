# RelationalQuery

This package allows to construct relational database queries of a simple form in an abstract way with output to various formats.

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
    orderBy: [.field("name"), .withDirection("prename", .descending)]
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

This library is published under the Apache License v2.0 with Runtime Library Exception.