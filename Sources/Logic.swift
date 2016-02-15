//
//  Logic.swift
//  Swiftlog
//
//  Created by Jaden Geller on 1/19/16.
//  Copyright © 2016 Jaden Geller. All rights reserved.
//

import Axiomatic
import Gluey

struct Logic {
    let system: Axiomatic.System<String>
    init(clauses: [Clause]) {
        var newClauses: [Axiomatic.Clause<String>] = []
        for clause in clauses {
            var variables: [String : Binding<Term<String>>] = [:]
            
            func predicateToAxiomatic(predicate: Predicate) -> Term<String> {
                return Term(
                    name: predicate.name,
                    arguments: predicate.arguments.map(nodeToAxiomatic)
                )
            }
            
            func nodeToAxiomatic(node: Node) -> Unifiable<Term<String>> {
                switch node {
                case .Variable(let name):
                    if let v = variables[name] {
                        return .Variable(v)
                    } else {
                        let v = Binding<Term<String>>()
                        variables[name] = v
                        return .Variable(v)
                    }
                case .Bare(let name):
                    return .Literal(Term(atom: name))
                case .Predicate(let pred):
                    return .Literal(predicateToAxiomatic(pred))
                }
            }
            let newClause = Axiomatic.Clause<String>(
                rule: predicateToAxiomatic(clause.head),
                conditions: clause.body.map(predicateToAxiomatic)
            )
            newClauses.append(newClause)
        }
        system = System(clauses: newClauses)
    }
    
    func query(predicates: [Predicate], onMatch: [String: String] throws -> ()) -> Bool {
        var variables: [String : Binding<Term<String>>] = [:]
        
        func predicateToAxiomatic(predicate: Predicate) -> Term<String> {
            return Term(
                name: predicate.name,
                arguments: predicate.arguments.map(nodeToAxiomatic)
            )
        }
        
        func nodeToAxiomatic(node: Node) -> Unifiable<Term<String>> {
            switch node {
            case .Variable(let name):
                if let v = variables[name] {
                    return .Variable(v)
                } else {
                    let v = Binding<Term<String>>()
                    variables[name] = v
                    return .Variable(v)
                }
            case .Bare(let name):
                return .Literal(Term(atom: name))
            case .Predicate(let pred):
                return .Literal(predicateToAxiomatic(pred))
            }
        }
        
        var newPredicates: [Term<String>] = []
        for p in predicates {
            newPredicates.append(predicateToAxiomatic(p))
        }
        
        var count = 0
        do {
            try system.enumerateMatches(newPredicates) {
                var results: [String : String] = [:]
                for (key, value) in variables {
                    results[key] = value.value?.description
                }
                try onMatch(results)
                count += 1
            }
        } catch {
        }
        return count > 0
    }
}