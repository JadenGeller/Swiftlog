//
//  main.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Axiomatic
import Parsley

let query = dropRight(
    separatedBy1(predicate, delimiter: between(whitespace, parse: character(","))),
    between(whitespace, parse: character("."))
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

guard Process.arguments.count == 2 else {
    fatalError("usage: \(Process.arguments[0]) [filename]")
}
let filename = Process.arguments[1]

let system: Logic
if let file = FileStream(filename) {
    do {
        let parsed = try terminating(logic).parse(file)
        system = Logic(clauses: parsed)
        print("Successfully loaded")
    }
    catch let error {
        fatalError("File contains invalid syntax: \(error)")
    }
} else {
    fatalError("Invalid filename")
}

do {
    while true {
        print("? ", terminator: "")
        guard let line = InputStream().getLine() else { throw InputError.EndOfFile }
        do {
            let q = try terminating(query).parse(line.characters)
            
            let success = system.query(q) { results in
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
        } catch {
            print("Input error")
        }
    }
} catch {
    print("")
}
