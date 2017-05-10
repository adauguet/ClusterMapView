//
//  JSONInstantiable.swift
//  Example
//
//  Created by Antoine DAUGUET on 10/05/2017.
//  Copyright © 2017 Antoine DAUGUET. All rights reserved.
//

protocol JSONInstantiable {
    init?(json: [String : Any])
    static func foo(json: [[String : Any]]) -> [Self]
}

extension JSONInstantiable {
    static func foo(json: [[String : Any]]) -> [Self] {
        return json.flatMap { Self.init(json: $0) }
    }
}
