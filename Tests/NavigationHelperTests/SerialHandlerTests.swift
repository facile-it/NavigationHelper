import XCTest
import FunctionalKit
@testable import NavigationHelper
import Foundation
import RxSwift

final class ExpectationExecutable<T>: Executable, Hashable {
	typealias Context = T
    
	private var fulfilled1 = false
	private var fulfilled2 = false
	private let expectation: (T) -> Bool
    
    let hashValue: Int
	init(hashValue: Int, expectation: @escaping (T) -> Bool) {
        self.hashValue = hashValue
		self.expectation = expectation
	}

	var fulfilled: Bool {
		return fulfilled1 && fulfilled2
	}

	var execution: Reader<T, Future<()>> {
		return Reader<T, Future<()>>.init {
			self.fulfilled1 = self.expectation($0)
			return Future<()>.init { done in
				self.fulfilled2 = true
				done(())
			}.start()
		}
	}

	static func == (lhs: ExpectationExecutable, rhs: ExpectationExecutable) -> Bool {
		return lhs === rhs
	}
}

class SerialHandlerTests: XCTestCase {
	typealias TestExecutable = ExpectationExecutable<Int>
	typealias TestHandler = SerialHandler<TestExecutable>

	func testSerialHandlerHandleOnce() {

		let expected = 42

		let handler = TestHandler(context: expected)
		let expectation = TestExecutable(hashValue: 1, expectation: { $0 == expected })

		var futureCompletion = false
		handler.handle(expectation).run { received in
			futureCompletion = received == expectation
		}

		expecting("both expectations fulfilled") { fulfill in
			after(0.1) {
				expectation.fulfilled ==! true
				futureCompletion ==! true
				fulfill()
			}
		}
	}

	func testSerialHandlerHandleTwice() {

		let expected = 42

		let handler = TestHandler(context: expected)
        let expectation1 = TestExecutable(hashValue: 1, expectation: { $0 == expected })
		let expectation2 = TestExecutable(hashValue: 2, expectation: { $0 == expected })

		var futureCompletion1 = false
		handler.handle(expectation1).run { received in
			futureCompletion1 = received == expectation1
		}

		var futureCompletion2 = false
		handler.handle(expectation2).run { received in
			futureCompletion2 = received == expectation2
		}

		expecting("both expectations fulfilled") { fulfill in
			after(0.1) {
				expectation1.fulfilled ==! true
				futureCompletion1 ==! true
				expectation2.fulfilled ==! true
				futureCompletion2 ==! true
				fulfill()
			}
		}
	}

    func testSerialHandlerHandleTwiceDelay() {

        let expected = 42

        let handler = TestHandler(context: expected)
        handler.interMessageDelay = 0.1
        let expectation1 = TestExecutable(hashValue: 1, expectation: { $0 == expected })
        let expectation2 = TestExecutable(hashValue: 2, expectation: { $0 == expected })

        var futureCompletion1 = false
        handler.handle(expectation1).run { received in
            futureCompletion1 = received == expectation1
        }

        var futureCompletion2 = false
        handler.handle(expectation2).run { received in
            futureCompletion2 = received == expectation2
        }

        expecting("both expectations fulfilled") { fulfill in
            after(0.2) {
                expectation1.fulfilled ==! true
                futureCompletion1 ==! true
                expectation2.fulfilled ==! true
                futureCompletion2 ==! true
                fulfill()
            }
        }
    }

    static var allTests = [
        ("testSerialHandlerHandleOnce", testSerialHandlerHandleOnce),
		("testSerialHandlerHandleTwice", testSerialHandlerHandleTwice),
    ]
}
