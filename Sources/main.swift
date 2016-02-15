//
//  main.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Axiomatic
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

enum InputError: ErrorType {
    case EndOfFile
}

do {
    var logicSystem: Logic? = nil
    while true {
        print("> ", terminator: "")
        guard let line = InputStream().getLine() else { throw InputError.EndOfFile }
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
                let success = system.query(query) { results in
                    if results.isEmpty {
                        print("True")
                    } else {
                        print(results)
                        while true {
                            guard let char = InputStream().getLine() else { throw InputError.EndOfFile }
                            switch char {
                            case "c":
                                throw SystemException.Continue
                            case "b":
                                throw SystemException.Break
                            default:
                                print("Unkown action. Type `c` to continue or `b` to break.")
                            }
                        }
                    }
                }
                if !success {
                    print("False")
                }
            }
        } catch {
            print("Input error")
        }
    }
} catch {
    print("")
}
