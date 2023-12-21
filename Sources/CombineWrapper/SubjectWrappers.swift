//
//  SubjectWrappers.swift
//
//
//  Created by Andre Elandra on 21/12/23.
//

import Foundation
import Combine

//MARK: Combine without Failure argument

public protocol CombineSubjectWrapper: AnyObject {
    associatedtype Subscribed
    var wrappedValue: Subscribed { get set }
    var projectedValue: Publishable<Subscribed> { get }
    func onSend(_ value: Subscribed)
    func onNever()
    func onCompleted()
}

public protocol CombineMutableSubjectWrapper: CombineSubjectWrapper {
    var projectedValue: Publishable<Subscribed> { get set }
}

/// A property wrapper to use Combine with `CurrentValueSubject`. A subject that wraps a single value and publishes a new element whenever the value changes.
///
/// This subject needs to have initial value and will buffer it as the most recent element.
/// You can assign value to the property annoted with this property wrapper and start observing it with a publisher.
/// You can use `Publishable` as a publisher which is a typealias for `AnyPublisher<Subscribed, Never>`.
///
/// For example:
/// ```
/// @CombineCurrentValue var str: String = "Initial value"
/// var strPublishable: Publishable<String> { $str }
///
/// init() {
///     str = "New value"
///     // From here you can start observing and receiving the publisher's emitted values.
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     }.stored(in: &cancellables)
/// }
/// ```
@propertyWrapper
public class CombineCurrentValue<Subscribed>: CombineSubjectWrapper {
    
    lazy var subject: CurrentValueSubject<Subscribed, Never> = .init(_wrappedValue)
    
    private var _wrappedValue: Subscribed
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = newValue
            subject.send(newValue)
        }
    }
    
    public var projectedValue: Publishable<Subscribed> {
        subject.eraseToAnyPublisher()
    }
    
    public init(wrappedValue: Subscribed) {
        _wrappedValue = wrappedValue
    }
    
    public func onSend(_ value: Subscribed) {
        wrappedValue = value
    }
    
    public func onNever() {
        print("Returned Never. Wrapped value: \(wrappedValue).")
    }
    
    public func onCompleted() {
        subject.send(completion: .finished)
    }
}

/// A property wrapper to use Combine with `PassthroughSubject`. This subject broadcasts elements to downstream subscribers.
///
/// This subject don't need to have initial value and will not buffer the most recent element. Instead, it will buffer the value when you emit a value to this subject after the subject is initialized.
/// You can assign value to the property annoted with this property wrapper and start observing it with a publisher.
/// You can use `Publishable` as a publisher which is a typealias for `AnyPublisher<Subscribed, Never>`.
///
/// For example:
/// ```
/// @CombinePassthrough var str: String
/// var strPublishable: Publishable<String> { $str }
///
/// init() {
///     str = "Example"
///     // From here you can start observing and receiving the publisher's emitted values.
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     }.stored(in: &cancellables)
/// }
/// ```
@propertyWrapper
public class CombinePassthrough<Subscribed>: CombineSubjectWrapper {
    
    lazy var subject: PassthroughSubject<Subscribed, Never> = .init()
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var _wrappedValue: Subscribed!
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = newValue
            subject.send(newValue)
        }
    }
    
    public var projectedValue: Publishable<Subscribed> {
        subject.eraseToAnyPublisher()
    }
    
    public init() { }
    
    public init(wrappedValue: Subscribed) {
        _wrappedValue = wrappedValue
    }
    
    public func onSend(_ value: Subscribed) {
        wrappedValue = value
    }
    
    public func onNever() {
        print("Returned Never. Wrapped value: \(wrappedValue).")
    }
    
    public func onCompleted() {
        subject.send(completion: .finished)
    }
}

/// A property wrapper to use Combine with manual subject assign.
///
/// When using this, you need to manually assign the available subjects in this class.
///
/// For example:
/// ```
/// @CombineManual var str: String
/// var strPublishable: Publishable<String> { $str }
///
/// init() {
///     _str.currentValueSubject = CurrentValueSubject<String, Never>("Example")
///     // From here you can start assigning the str variable and subscribe the publisher's emitted values.
///     str = "New value"
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     }.stored(in: &cancellables)
/// }
/// ```
/// When you assign the subject, it will automatically set its publisher to the property wrapper's projected value which will enable you to start assigning the value to the property and automatically publish its value to the assigned subject.
@propertyWrapper
public class CombineManual<Subscribed>: CombineMutableSubjectWrapper {
    
    lazy var subject: Publishable<Subscribed> = PassthroughSubject<Subscribed, Never>().eraseToAnyPublisher()
    
    /// A subject that broadcasts elements to downstream subscribers.
    ///
    /// This is one of the subjects you can use by manually assign it to start using CombineManual.
    public var passthroughSubject: PassthroughSubject<Subscribed, Never>? {
        didSet {
            guard let passthroughSubject else { return }
            projectedValue = passthroughSubject.eraseToAnyPublisher()
        }
    }
    
    /// A subject that wraps a single value and publishes a new element whenever the value changes.
    ///
    /// This is one of the subjects you can use by manually assign it to start using CombineManual.
    public var currentValueSubject: CurrentValueSubject<Subscribed, Never>? {
        didSet {
            guard let currentValueSubject else { return }
            projectedValue = currentValueSubject.eraseToAnyPublisher()
        }
    }
    
    private var internalCancellable: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var _wrappedValue: Subscribed!
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            guard trySetNext(newValue) else {
                print("Failed to publish value with subject: \(projectedValue)")
                return
            }
            _wrappedValue = newValue
        }
    }
    
    public var projectedValue: Publishable<Subscribed> {
        get {
            if let passthroughSubject = passthroughSubject {
                return passthroughSubject.eraseToAnyPublisher()
            } else if let currentValueSubject = currentValueSubject {
                return currentValueSubject.eraseToAnyPublisher()
            } else {
                return subject
            }
        }
        set {
            internalCancellable = Set<AnyCancellable>()
            subject = newValue
            subject.sinkReceiveValue { [weak self] value in
                self?._wrappedValue = value
            }.store(in: &internalCancellable)
        }
    }
    
    @discardableResult
    func trySetNext(_ value: Subscribed) -> Bool {
        if let passthroughSubject = passthroughSubject {
            passthroughSubject.send(value)
        } else if let currentValueSubject = currentValueSubject {
            currentValueSubject.send(value)
        } else {
            return false
        }
        return true
    }
    
    public init(wrappedValue: Subscribed) {
        self.wrappedValue = wrappedValue
    }
    
    public init() { }
    
    public func onCompleted() {
        if let passthroughSubject = passthroughSubject {
            passthroughSubject.send(completion: .finished)
        } else if let currentValueSubject = currentValueSubject {
            currentValueSubject.send(completion: .finished)
        }
    }
    
    public func onNever() {
        print("Returned Never. Wrapped value: \(wrappedValue).")
    }
    
    public func onSend(_ value: Subscribed) {
        _wrappedValue = value
        trySetNext(value)
    }
}

//MARK: Combine with Failure argument

public protocol CombineSubjectResultWrapper: AnyObject {
    associatedtype Subscribed
    var wrappedValue: Subscribed { get set }
    var projectedValue: PublishableResult<Subscribed> { get }
    func onSend(_ value: Subscribed)
    func onError(_ error: Error)
    func onCompleted()
}

public protocol CombineMutableSubjectResultWrapper: CombineSubjectResultWrapper {
    var projectedValue: PublishableResult<Subscribed> { get set }
}

/// A property wrapper to use Combine with `CurrentValueSubject`. A subject that wraps a single value and publishes a new element whenever the value changes.
///
/// This subject needs to have initial value and will buffer it as the most recent element.
/// You can assign value to the property annoted with this property wrapper and start observing it with a publisher.
/// You can use `PublishableResult` as a publisher which is a typealias for `AnyPublisher<Subscribed, Error>`.
///
/// For example:
/// ```
/// @CombineCurrentValueResult var str: String = "Initial value"
/// var strPublishable: PublishableResult<String> { $str }
///
/// init() {
///     str = "New value"
///     // From here you can start observing and receiving the publisher's emitted values.
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     } completion: { result in
///         switch result {
///         case .finished:
///         print("succeed")
///         case .failure(let error):
///         print("failed")
///         }
///     }.stored(in: &cancellables)
/// }
/// ```
@propertyWrapper
public class CombineCurrentValueResult<Subscribed>: CombineSubjectResultWrapper {
    
    lazy var subject: CurrentValueSubject<Subscribed, Error> = .init(_wrappedValue)
    
    private var _wrappedValue: Subscribed
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = newValue
            subject.send(newValue)
        }
    }
    
    public var projectedValue: PublishableResult<Subscribed> {
        subject.eraseToAnyPublisher()
    }
    
    public init(wrappedValue: Subscribed) {
        _wrappedValue = wrappedValue
    }
    
    public func onSend(_ value: Subscribed) {
        wrappedValue = value
    }
    
    public func onError(_ error: Error) {
        subject.send(completion: .failure(error))
    }
    
    public func onCompleted() {
        subject.send(completion: .finished)
    }
}

/// A property wrapper to use Combine with `PassthroughSubject`. This subject broadcasts elements to downstream subscribers.
///
/// This subject don't need to have initial value and will not buffer the most recent element. Instead, it will buffer the value when you emit a value to this subject after the subject is initialized.
/// You can assign value to the property annoted with this property wrapper and start observing it with a publisher.
/// You can use `PublishableResult` as a publisher which is a typealias for `AnyPublisher<Subscribed, Error>`.
///
/// For example:
/// ```
/// @CombinePassthroughResult var str: String
/// var strPublishable: PublishableResult<String> { $str }
///
/// init() {
///     str = "New value"
///     // From here you can start observing and receiving the publisher's emitted values.
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     } completion: { result in
///         switch result {
///         case .finished:
///         print("succeed")
///         case .failure(let error):
///         print("failed")
///         }
///     }.stored(in: &cancellables)
/// }
/// ```
@propertyWrapper
public class CombinePassthroughResult<Subscribed>: CombineSubjectResultWrapper {
    
    lazy var subject: PassthroughSubject<Subscribed, Error> = .init()
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var _wrappedValue: Subscribed!
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            _wrappedValue = newValue
            subject.send(newValue)
        }
    }
    
    public var projectedValue: PublishableResult<Subscribed> {
        subject.eraseToAnyPublisher()
    }
    
    public init() { }
    
    public init(wrappedValue: Subscribed) {
        _wrappedValue = wrappedValue
    }
    
    public func onSend(_ value: Subscribed) {
        wrappedValue = value
    }
    
    public func onError(_ error: Error) {
        subject.send(completion: .failure(error))
    }
    
    public func onCompleted() {
        subject.send(completion: .finished)
    }
}

/// A property wrapper to use Combine with manual subject assign.
///
/// When using this, you need to manually assign the available subjects in this class.
///
/// For example:
/// ```
/// @CombineManualResult var str: String
/// var strPublishable: PublishableResult<String> { $str }
///
/// init() {
///     _str.currentValueSubject = CurrentValueSubject<String, Error>("Example")
///     // From here you can start assigning the str variable and subscribe the publisher's emitted values.
///     str = "New value"
///     strPublishable.sinkReceiveValue { [weak self] value in
///         print(value)
///     } completion: { result in
///         switch result {
///         case .finished:
///         print("succeed")
///         case .failure(let error):
///         print("failed")
///         }
///     }.stored(in: &cancellables)
/// }
/// ```
/// When you assign the subject, it will automatically set its publisher to the property wrapper's projected value which will enable you to start assigning the value to the property and automatically publish its value to the assigned subject.
@propertyWrapper
public class CombineManualResult<Subscribed>: CombineMutableSubjectResultWrapper {
    
    lazy var subject: PublishableResult<Subscribed> = PassthroughSubject<Subscribed, Error>().eraseToAnyPublisher()
    
    /// A subject that broadcasts elements to downstream subscribers.
    ///
    /// This is one of the subjects you can use by manually assign it to start using CombineManualResult.
    public var passthroughSubject: PassthroughSubject<Subscribed, Error>? {
        didSet {
            guard let passthroughSubject else { return }
            projectedValue = passthroughSubject.eraseToAnyPublisher()
        }
    }
    
    /// A subject that wraps a single value and publishes a new element whenever the value changes.
    ///
    /// This is one of the subjects you can use by manually assign it to start using CombineManual.
    public var currentValueSubject: CurrentValueSubject<Subscribed, Error>? {
        didSet {
            guard let currentValueSubject else { return }
            projectedValue = currentValueSubject.eraseToAnyPublisher()
        }
    }
    
    private var internalCancellable: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var _wrappedValue: Subscribed!
    public var wrappedValue: Subscribed {
        get {
            _wrappedValue
        }
        set {
            guard trySetNext(newValue) else {
                print("Failed to publish value with subject: \(projectedValue)")
                return
            }
            _wrappedValue = newValue
        }
    }
    
    public var projectedValue: PublishableResult<Subscribed> {
        get {
            if let passthroughSubject = passthroughSubject {
                return passthroughSubject.eraseToAnyPublisher()
            } else if let currentValueSubject = currentValueSubject {
                return currentValueSubject.eraseToAnyPublisher()
            } else {
                return subject
            }
        }
        set {
            internalCancellable = Set<AnyCancellable>()
            subject = newValue
            subject.sinkReceiveValue { [weak self] value in
                self?._wrappedValue = value
            } completion: { _ in
            }.store(in: &internalCancellable)
        }
    }
    
    @discardableResult
    func trySetNext(_ value: Subscribed) -> Bool {
        if let passthroughSubject = passthroughSubject {
            passthroughSubject.send(value)
        } else if let currentValueSubject = currentValueSubject {
            currentValueSubject.send(value)
        } else {
            return false
        }
        return true
    }
    
    public init(wrappedValue: Subscribed) {
        self.wrappedValue = wrappedValue
    }
    
    public init() { }
    
    public func onError(_ error: Error) {
        if let passthroughSubject = passthroughSubject {
            passthroughSubject.send(completion: .failure(error))
        } else if let currentValueSubject = currentValueSubject {
            currentValueSubject.send(completion: .failure(error))
        }
    }
    
    public func onCompleted() {
        if let passthroughSubject = passthroughSubject {
            passthroughSubject.send(completion: .finished)
        } else if let currentValueSubject = currentValueSubject {
            currentValueSubject.send(completion: .finished)
        }
    }
    
    public func onSend(_ value: Subscribed) {
        _wrappedValue = value
        trySetNext(value)
    }
}
