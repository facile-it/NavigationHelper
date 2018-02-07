import FunctionalKit

public protocol Executable {
	associatedtype Context

	var execution: Reader<Context,Future<()>> { get }
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
	var lastPresented: Presentable? { get }

	func show(animated: Bool) -> Reader<Presentable,Future<()>>
	func hide(animated: Bool) -> Future<()>
}

extension ModalPresenter {
	public var isPresenting: Bool {
		return lastPresented.isNil.not
	}
}

public protocol StructuredPresenter {
	var allPresented: [Presentable] { get }

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

	public var lastPresented: Presentable? {
		return modalPresenter.lastPresented
	}

	public func show(animated: Bool) -> Reader<Presentable, Future<()>> {
		return modalPresenter.show(animated: animated)
	}

	public func hide(animated: Bool) -> Future<()> {
		return modalPresenter.hide(animated: animated)
	}

	public var allPresented: [Presentable] {
		return structuredPresenter.allPresented
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
