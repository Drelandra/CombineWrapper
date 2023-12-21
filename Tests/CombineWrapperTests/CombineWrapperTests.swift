import XCTest
import Combine
@testable import CombineWrapper

final class CombineWrapperTests: XCTestCase {
    
    @CombineCurrentValue var currentValueSubjectNumber: Int = 0
    var currentValueSubjectNumberPublishable: Publishable<Int> { $currentValueSubjectNumber }
    
    @CombineCurrentValueResult var currentValueResultSubjectNumber: Int = 0
    var currentValueResultSubjectNumberPublishable: PublishableResult<Int> { $currentValueResultSubjectNumber }
    
    @CombinePassthrough var passthroughSubjectNumber: Int
    var passthroughSubjectNumberPublishable: Publishable<Int> { $passthroughSubjectNumber }
    
    @CombinePassthroughResult var passthroughResultSubjectNumber: Int
    var passthroughResultSubjectNumberPublishable: PublishableResult<Int> { $passthroughResultSubjectNumber }
    
    @CombineManual var manualSubjectNumber: Int
    var manualSubjectNumberPublishable: Publishable<Int> { $manualSubjectNumber }
    
    @CombineManualResult var manualResultSubjectNumber: Int
    var manualResultSubjectNumberPublishable: PublishableResult<Int> { $manualResultSubjectNumber}
    
    var cancellables = Set<AnyCancellable>()
    
    func testCurrentSubjectWrapper() {
        var isAssigned: Bool = false
        
        currentValueSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isAssigned {
                XCTAssertTrue(emittedValue == 1 && self?.currentValueSubjectNumber == 1)
            } else {
                XCTAssertTrue(emittedValue == 0 && self?.currentValueSubjectNumber == 0)
            }
        }.store(in: &cancellables)
        
        isAssigned = true
        currentValueSubjectNumber = 1
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        currentValueSubjectNumber = 2
    }
    
    func testCurrentSubjectResultWrapper() {
        var isAssigned: Bool = false
        var isCompleted: Bool = false
        var isFailed: Bool = false
        
        currentValueResultSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isAssigned {
                XCTAssertTrue(emittedValue == 1 && self?.currentValueResultSubjectNumber == 1)
            } else {
                XCTAssertTrue(emittedValue == 0 && self?.currentValueResultSubjectNumber == 0)
            }
        } completion: { result in
            switch result {
            case .finished:
                XCTAssertTrue(isCompleted, "The specific line of code was not executed as expected")
            case .failure(let error):
                XCTAssertTrue(isFailed, "The specific line of code was not executed as expected")
            }
        }.store(in: &cancellables)
        
        isAssigned = true
        currentValueResultSubjectNumber = 1
        
        isCompleted = true
        _currentValueResultSubjectNumber.onCompleted()
        
        isFailed = true
        _currentValueResultSubjectNumber.onError(NSError(domain: "", code: -1, userInfo: nil))
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        currentValueResultSubjectNumber = 2
    }
    
    func testPassthroughSubjectWrapper() {
        var isSecondAssign: Bool = false
        
        passthroughSubjectNumber = 1
        passthroughSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isSecondAssign {
                XCTAssertTrue(emittedValue == 2 && self?.passthroughSubjectNumber == 2)
            } else {
                XCTAssertTrue(emittedValue == 1 && self?.passthroughSubjectNumber == 1)
            }
        }.store(in: &cancellables)
        
        isSecondAssign = true
        passthroughSubjectNumber = 2
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        passthroughSubjectNumber = 3
    }
    
    func testPassthroughSubjectResultWrapper() {
        var isSecondAssign: Bool = false
        var isCompleted: Bool = false
        var isFailed: Bool = false
        
        passthroughResultSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isSecondAssign {
                XCTAssertTrue(emittedValue == 1 && self?.passthroughResultSubjectNumber == 1)
            } else {
                XCTAssertTrue(emittedValue == 0 && self?.passthroughResultSubjectNumber == 0)
            }
        } completion: { result in
            switch result {
            case .finished:
                XCTAssertTrue(isCompleted, "The specific line of code was not executed as expected")
            case .failure(let error):
                XCTAssertTrue(isFailed, "The specific line of code was not executed as expected")
            }
        }.store(in: &cancellables)
        
        isSecondAssign = true
        passthroughResultSubjectNumber = 1
        
        isCompleted = true
        _passthroughResultSubjectNumber.onCompleted()
        
        isFailed = true
        _passthroughResultSubjectNumber.onError(NSError(domain: "", code: -1, userInfo: nil))
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        passthroughResultSubjectNumber = 2
    }
    
    func testManualSubjectWrapper() {
        var isSubjectAssigned: Bool = false
        var isAssigned: Bool = false
        
        manualSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isAssigned {
                XCTAssertTrue(emittedValue == 1 && self?.manualSubjectNumber == 1)
            } else {
                if isSubjectAssigned {
                    XCTAssertTrue(emittedValue == 0 && self?.manualSubjectNumber == 0)
                } else {
                    XCTAssertTrue(emittedValue == 0 && self?.manualSubjectNumber == nil)
                }
            }
        }.store(in: &cancellables)
        
        isSubjectAssigned = true
        _manualSubjectNumber.currentValueSubject = CurrentValueSubject<Int, Never>(0)
        
        isAssigned = true
        manualSubjectNumber = 1
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        manualSubjectNumber = 2
    }
    
    func testManualResultSubjectWrapper() {
        var isSubjectAssigned: Bool = false
        var isAssigned: Bool = false
        var isCompleted: Bool = false
        var isFailed: Bool = false
        
        manualResultSubjectNumberPublishable.sinkReceiveValue { [weak self] emittedValue in
            if isAssigned {
                XCTAssertTrue(emittedValue == 1 && self?.manualResultSubjectNumber == 1)
            } else {
                if isSubjectAssigned {
                    XCTAssertTrue(emittedValue == 0 && self?.manualResultSubjectNumber == 0)
                } else {
                    XCTAssertTrue(emittedValue == 0 && self?.manualResultSubjectNumber == nil)
                }
            }
        }completion: { result in
            switch result {
            case .finished:
                XCTAssertTrue(isCompleted)
            case .failure(let error):
                XCTAssertTrue(isFailed)
            }
        }.store(in: &cancellables)
        
        isSubjectAssigned = true
        _manualResultSubjectNumber.currentValueSubject = CurrentValueSubject<Int, Error>(0)
        
        isAssigned = true
        manualSubjectNumber = 1
        
        isCompleted = true
        _manualResultSubjectNumber.onCompleted()
        
        isFailed = true
        _manualResultSubjectNumber.onError(NSError(domain: "", code: -1, userInfo: nil))
        
        XCTAssertTrue(cancellables.count == 1)
        cancellables.forEach({ $0.cancel() })
        manualSubjectNumber = 2
    }
}
