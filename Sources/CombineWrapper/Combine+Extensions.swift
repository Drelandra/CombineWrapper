//
//  Combine+Extensions.swift
//
//
//  Created by Andre Elandra on 21/12/23.
//

import Foundation
import Combine
import UIKit

public typealias Publishable<T> = AnyPublisher<T, Never>
public typealias PublishableResult<T> = AnyPublisher<T, Error>

//MARK: - Publisher General Methods

public extension Publisher {
    
    func filterToPublisher(_ isIncluded: @escaping (Output) -> Bool) -> AnyPublisher<Output, Self.Failure> {
        filter(isIncluded).eraseToAnyPublisher()
    }
    
    func mapToPublisher<T>(transform: @escaping (Output) -> T) -> AnyPublisher<T, Self.Failure> {
        map(transform).eraseToAnyPublisher()
    }
    
    func compactMapToPublisher<T>(transform: @escaping (Output) -> T?) -> AnyPublisher<T, Self.Failure> {
        compactMap(transform).eraseToAnyPublisher()
    }
}

//MARK: - Publisher without Failure argument

public extension Publisher where Failure == Never {
    
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
    
    func sinkReceiveValue(run receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        sink(receiveValue: receiveValue)
    }
    
    func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
    
    func weakSink<T: AnyObject>(
        on object: T,
        receiveValue: @escaping (T, Self.Output) -> Void
    ) -> AnyCancellable {
        sink { [weak object] output in
            guard let strongRef = object else { return }
            receiveValue(strongRef, output)
        }
    }
    
    func relayValue<Wrapper: CombineSubjectWrapper>(
        to subjectWrapper: Wrapper
    ) -> AnyCancellable where Wrapper.Subscribed == Output {
        weak var wrapper: Wrapper? = subjectWrapper
        return sink { completion in
            switch completion {
            case .finished:
                wrapper?.onCompleted()
            case .failure:
                wrapper?.onNever()
            }
        } receiveValue: { value in
            wrapper?.onSend(value)
        }
    }
    
    @available(iOS 14.0, *)
    func flatMapToPublisher<P: Publisher>(
        maxPublishers: Subscribers.Demand = .unlimited,
        transform: @escaping (Output) -> P
    ) -> AnyPublisher<P.Output, P.Failure> {
        flatMap(maxPublishers: maxPublishers, transform).eraseToAnyPublisher()
    }
}

//MARK: - Publisher with Failure argument

public extension Publisher where Failure == Error {
    
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
    
    func sinkReceiveValue(
        run receiveValue: @escaping ((Self.Output) -> Void),
        completion receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void)
    ) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }
    
    func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        sink { _ in } receiveValue: { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
    
    func weakSink<T: AnyObject>(
        on object: T,
        receiveValue: @escaping (T, Self.Output) -> Void
    ) -> AnyCancellable {
        sink { _ in } receiveValue: { [weak object] output in
            guard let strongRef = object else { return }
            receiveValue(strongRef, output)
        }
    }
    
    func relayValue<Wrapper: CombineSubjectResultWrapper>(
        to subjectWrapper: Wrapper
    ) -> AnyCancellable where Wrapper.Subscribed == Output {
        weak var wrapper: Wrapper? = subjectWrapper
        return sink { completion in
            switch completion {
            case .finished:
                wrapper?.onCompleted()
            case .failure(let error):
                wrapper?.onError(error)
            }
        } receiveValue: { value in
            wrapper?.onSend(value)
        }
    }
    
    @available(iOS 14.0, *)
    func flatMapToPublisher<P: Publisher>(
        maxPublishers: Subscribers.Demand = .unlimited,
        transform: @escaping (Self.Output) -> P
    ) -> AnyPublisher<P.Output, P.Failure> where P.Failure == Error {
        flatMap(maxPublishers: maxPublishers, transform).eraseToAnyPublisher()
    }
}

//MARK: - Notification Publishers

public extension UITextField {
    func textDidChangePublisher() -> AnyPublisher<String, Never> {
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: self)
            .map { ($0.object as? UITextField)?.text  ?? "" }
            .eraseToAnyPublisher()
    }
}
