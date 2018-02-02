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

public protocol StructuredPresenter {
	var allPresented: [Presentable] { get }

	func resetTo(animated: Bool) -> Reader<[Presentable],Future<()>>
	func moveTo(animated: Bool) -> Reader<Presentable,Future<()>>
	func dropLast(animated: Bool) -> Future<()>
}

public typealias Presenter = ModalPresenter & StructuredPresenter
