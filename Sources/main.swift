//
//  main.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Parsley

enum Command {
    case Open(String)
    case Clear
}

let open = dropLeft(
    pair(string("$load"), whitespace),
    many1(letter ?? digit ?? character(".") ?? character("/"))
).withError("open").stringify().map(Command.Open)

let clear = string("$clear").withError("clear").replace(Command.Clear)

let query = dropLeft(
    between(whitespace, parse: character("?")),
    dropRight(
        separatedBy1(predicate, delimiter: between(whitespace, parse: character(","))),
        between(whitespace, parse: character("."))
    )
)

let logic = many(Parser<Character, Clause> { state in
    try whitespace.parse(state)
    let c = try clause.parse(state)
    try whitespace.parse(state)
    try character(".").parse(state)
    try whitespace.parse(state)
    return c
})

var logicSystem: Logic? = nil
while true {
    let line = InputStream().getLine()
    do {
        let input = try terminating(either(open ?? clear, query)).parse(line.characters)
        switch input {
        case .Left(.Clear):
            print("clear")
        case .Left(.Open(let filename)):
            if let file = FileStream(filename) {
                do {
                    let parsed = try terminating(logic).parse(file)
                    logicSystem = Logic(clauses: parsed)
                    print("Successfully loaded")
                }
                catch let error {
                    print("File contains invalid syntax: \(error)")
                }
            } else {
                print("Invalid filename")
            }
        case .Right(let query):
            guard let system = logicSystem else {
                print("Cannot execute query before loading file")
                continue
            }
            print(system.query(query))
        }
    } catch {
        print("Input error")
    }
}
