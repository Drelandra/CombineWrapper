//
//  Canceller.swift
//  
//
//  Created by Andre Elandra on 21/12/23.
//

import Foundation
import UIKit
import Combine

public protocol Canceller {
    var cancellables: Set<AnyCancellable> { get set }
    @discardableResult
    func clearCancellables() -> Set<AnyCancellable>?
}

fileprivate var cancellablesAssociatedKey: UInt8 = 0

/// Intended to reduce the cancellable declaration when called by types that inherits UIResponder.
extension UIResponder: Canceller {
    
    public var cancellables: Set<AnyCancellable> {
        get {
            guard let cancellableNSSet = objc_getAssociatedObject(self, &cancellablesAssociatedKey) as? NSSet else {
                let newCancellables = NSSet()
                objc_setAssociatedObject(self, &cancellablesAssociatedKey, newCancellables, .OBJC_ASSOCIATION_RETAIN)
                return Set<AnyCancellable>()
            }
            let cancellableSet = cancellableNSSet.convertToSet(AnyCancellable.self)
            return cancellableSet
        }
        set {
            let newCancellables = NSSet(set: newValue)
            objc_setAssociatedObject(self, &cancellablesAssociatedKey, newCancellables, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    @discardableResult
    public func clearCancellables() -> Set<AnyCancellable>? {
        defer {
            let newCancellables = NSSet()
            objc_setAssociatedObject(self, &cancellablesAssociatedKey, newCancellables, .OBJC_ASSOCIATION_RETAIN)
        }
        let oldCancellables = objc_getAssociatedObject(self, &cancellablesAssociatedKey) as? NSSet
        if let oldCancellables = oldCancellables?.convertToSet(AnyCancellable.self) {
            oldCancellables.forEach({ $0.cancel() })
            return oldCancellables
        }
        return nil
    }
}
