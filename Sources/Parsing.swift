//
//  Parsing.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Parsley

enum Node: Equatable {
    case Variable(String)
    case Bare(String)
    indirect case Predicate(Swiftlog.Predicate)
}

struct Predicate: Equatable {
    let name: String
    let arguments: [Node]
}

struct Clause: Equatable {
    let head: Predicate
    let body: [Predicate]
}

let variable = (prepend(uppercaseLetter, many(letter ?? digit ?? character("_"))) ?? character("_").lift())
    .withError("variable").stringify()

let bare = prepend(lowercaseLetter, many(letter ?? digit ?? character("_")))
    .withError("variable").stringify()

let predicate = recursive { predicate in
    Parser<Character, Predicate> { state in
        let name = try bare.parse(state)
        try character("(").parse(state)
        try whitespace.parse(state)
        let arguments = try separatedBy1(coalesce(
            predicate.map(Node.Predicate),
            bare.map(Node.Bare),
            variable.map(Node.Variable)
        ), delimiter: between(whitespace, parse: character(","))).parse(state)
        try whitespace.parse(state)
        try character(")").parse(state)
        return Predicate(name: name, arguments: arguments)
    }
}.withError("predicate")

let clause = Parser<Character, Clause> { state in
    let head = try predicate.parse(state)
    try whitespace.parse(state)
    
    let body: Array = try optional(Parser<Character, [Predicate]> { state in
        try string(":-").parse(state)
        try whitespace.parse(state)
        let body = try separatedBy1(predicate, delimiter: between(whitespace, parse: character(","))).parse(state)
        try whitespace.parse(state)
        return body
    }).parse(state)
    
    return Clause(head: head, body: body)
}

func ==(lhs: Clause, rhs: Clause) -> Bool {
    return lhs.head == rhs.head && lhs.body == rhs.body
}

func ==(lhs: Predicate, rhs: Predicate) -> Bool {
    return lhs.name == rhs.name && lhs.arguments == rhs.arguments
}

func ==(lhs: Node, rhs: Node) -> Bool {
    switch (lhs, rhs) {
    case let (.Variable(l), .Variable(r)):
        return l == r
    case let (.Bare(l), .Bare(r)):
        return l == r
    case let (.Predicate(l), .Predicate(r)):
        return l == r
    default:
        return false
    }
}

