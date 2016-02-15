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
            var variables: [String : Binding<Axiomatic.Predicate<String>>] = [:]
            
            func predicateToAxiomatic(predicate: Predicate) -> Axiomatic.Predicate<String> {
                return Axiomatic.Predicate(
                    name: predicate.name,
                    arguments: predicate.arguments.map(nodeToAxiomatic)
                )
            }
            
            func nodeToAxiomatic(node: Node) -> Term<Axiomatic.Predicate<String>> {
                switch node {
                case .Variable(let name):
                    if let v = variables[name] {
                        return .Variable(v)
                    } else {
                        let v = Binding<Axiomatic.Predicate<String>>()
                        variables[name] = v
                        return .Variable(v)
                    }
                case .Bare(let name):
                    return .Constant(Axiomatic.Predicate(atom: name))
                case .Predicate(let pred):
                    return .Constant(predicateToAxiomatic(pred))
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
    
    func query(predicates: [Predicate]) -> [String: String]? {
        var variables: [String : Binding<Axiomatic.Predicate<String>>] = [:]
        
        func predicateToAxiomatic(predicate: Predicate) -> Axiomatic.Predicate<String> {
            return Axiomatic.Predicate(
                name: predicate.name,
                arguments: predicate.arguments.map(nodeToAxiomatic)
            )
        }
        
        func nodeToAxiomatic(node: Node) -> Term<Axiomatic.Predicate<String>> {
            switch node {
            case .Variable(let name):
                if let v = variables[name] {
                    return .Variable(v)
                } else {
                    let v = Binding<Axiomatic.Predicate<String>>()
                    variables[name] = v
                    return .Variable(v)
                }
            case .Bare(let name):
                return .Constant(Axiomatic.Predicate(atom: name))
            case .Predicate(let pred):
                return .Constant(predicateToAxiomatic(pred))
            }
        }
        
        var newPredicates: [Axiomatic.Predicate<String>] = []
        for p in predicates {
            newPredicates.append(predicateToAxiomatic(p))
        }
        
        var results: [String : String] = [:]
        var count = 0
        _ = try? system.enumerateMatches(newPredicates) {
            for (key, value) in variables {
                results[key] = value.value?.description
            }
            count += 1
        }
        
        guard count > 0 else { return nil }
        return results
    }
}