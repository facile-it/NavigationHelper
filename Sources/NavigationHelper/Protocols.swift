import FunctionalKit
import RxSwift

public protocol Executable {
	associatedtype Context

	var execution: Reader<Context,Future<()>> { get }
}

public protocol Disposer: class {
    var bag: DisposeBag { get }
}

public protocol Presentable {
	var hashable: AnyHashable { get }
}

extension Presentable {
	public func isEqual(to other: Presentable) -> Bool {
		return hashable == other.hashable
	}
}

public protocol ModalPresenter {
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

public protocol StructuredPresenter {
	var shouldAnimate: Bool { get }
	var allStructuredPresented: [Presentable] { get }

	func resetTo(animated: Bool) -> Reader<[Presentable],Future<()>>
	func moveTo(animated: Bool) -> Reader<Presentable,Future<()>>
	func dropLast(animated: Bool) -> Future<()>
}

public typealias Presenter = ModalPresenter & StructuredPresenter

public final class AnyPresenter: Presenter {
	private let modalPresenter: ModalPresenter
	private let structuredPresenter: StructuredPresenter

	public init(modalPresenter: ModalPresenter, structuredPresenter: StructuredPresenter) {
		self.modalPresenter = modalPresenter
		self.structuredPresenter = structuredPresenter
	}

	public convenience init(_ presenter: Presenter) {
		self.init(modalPresenter: presenter, structuredPresenter: presenter)
	}

	public var shouldAnimate: Bool {
		return structuredPresenter.shouldAnimate
	}

	public var currentModalPresented: Presentable? {
		return modalPresenter.currentModalPresented
	}

	public func show(animated: Bool) -> Reader<Presentable, Future<()>> {
		return modalPresenter.show(animated: animated)
	}

	public func hide(animated: Bool) -> Future<()> {
		return modalPresenter.hide(animated: animated)
	}

	public var allStructuredPresented: [Presentable] {
		return structuredPresenter.allStructuredPresented
	}

	public func resetTo(animated: Bool) -> Reader<[Presentable], Future<()>> {
		return structuredPresenter.resetTo(animated: animated)
	}

	public func moveTo(animated: Bool) -> Reader<Presentable, Future<()>> {
		return structuredPresenter.moveTo(animated: animated)
	}

	public func dropLast(animated: Bool) -> Future<()> {
		return structuredPresenter.dropLast(animated: animated)
	}
}
