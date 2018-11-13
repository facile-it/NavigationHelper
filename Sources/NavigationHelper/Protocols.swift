import FunctionalKit
import RxSwift

public protocol Executable {
	associatedtype Context

	var execution: Reader<Context,Future<()>> { get }
}

public protocol Disposer: class {
    var bag: DisposeBag { get }
}

public protocol Presentable: class {
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

	func show(animated: Bool) -> Reader<Presentable,Future<()>>
	func hide(animated: Bool) -> Future<()>
}

extension ModalPresenter {
	public var isPresenting: Bool {
		return currentModalPresented.isNil.not
	}

	public func hideAll(animated: Bool) -> Future<()> {
		guard isPresenting else { return .pure(()) }
		return hide(animated: animated).flatMap {
			self.hideAll(animated: true)
		}
	}
}

public protocol StructuredPresenter: PresentableOwner {
	var shouldAnimate: Bool { get }
	var allStructuredPresented: [Presentable] { get }

	func resetTo(animated: Bool) -> Reader<[Presentable],Future<()>>
	func moveTo(animated: Bool) -> Reader<Presentable,Future<()>>
	func dropLast(animated: Bool) -> Future<()>
}

public typealias Presenter = ModalPresenter & StructuredPresenter

public protocol TransitionHandlerType {
    func handle(_ message: Transition) -> Future<Transition>
}

public protocol TransitionHandlerOwner {
    var transitionHandler: TransitionHandler { get }
}
