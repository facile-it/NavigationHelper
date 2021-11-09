import FunctionalKit
import RxSwift

public protocol Executable {
	associatedtype Context

	var execution: Reader<Context,Future<Void>> { get }
}

public protocol Disposer: AnyObject {
    var bag: DisposeBag { get }
}

public protocol Presentable: AnyObject {
	var hashable: AnyHashable { get }
}

extension Presentable {
	public func isEqual(to other: Presentable) -> Bool {
		return hashable == other.hashable
	}
}

public protocol PresentableOwner {
    var presentable: Presentable { get }
}

public protocol ModalPresenter: PresentableOwner {
	var currentModalPresented: Presentable? { get }

	func show(animated: Bool) -> Reader<Presentable,Future<Void>>
	func hide(animated: Bool) -> Future<Void>
}

extension ModalPresenter {
	public var isPresenting: Bool {
		return currentModalPresented.isNil.not
	}

	public func hideAll(animated: Bool) -> Future<Void> {
		guard isPresenting else { return .pure(()) }
		return hide(animated: animated).flatMap {
			self.hideAll(animated: true)
		}
	}
}

public protocol StructuredPresenter: PresentableOwner {
	var shouldAnimate: Bool { get }
	var allStructuredPresented: [Presentable] { get }

	func resetTo(animated: Bool) -> Reader<[Presentable],Future<Void>>
	func moveTo(animated: Bool) -> Reader<Presentable,Future<Void>>
	func dropLast(animated: Bool) -> Future<Void>
}

public typealias Presenter = ModalPresenter & StructuredPresenter

public protocol TransitionHandlerType {
    func handle(_ message: Transition) -> Future<Transition>
}

public protocol TransitionHandlerOwner {
    var transitionHandler: TransitionHandler { get }
}
