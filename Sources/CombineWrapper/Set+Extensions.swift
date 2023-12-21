//
//  Set+Extensions.swift
//  
//
//  Created by Andre Elandra on 21/12/23.
//

import Foundation

public extension NSSet {
    func convertToSet<T>(_ type: T.Type) -> Set<T> {
        var set = Set<T>()
        for object in self {
            if let tObject = object as? T {
                set.insert(tObject)
            }
        }
        return set
    }
}
