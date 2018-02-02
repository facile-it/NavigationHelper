import FunctionalKit

public protocol Executable {
	associatedtype Context

	var execution: Reader<Context,Future<()>> { get }
}

public protocol Presentable {
	var hashable: AnyHashable { get }
}

public protocol ModalPresenter {
	var lastPresented: Presentable? { get }

	func present(value: Presentable, animated: Bool) -> Future<()>
	func dismiss(animated: Bool) -> Future<()>
}

public protocol StructuredPresenter {
	var allPresented: [Presentable] { get }

	func reset(value: [Presentable], animated: Bool) -> Future<()>
	func push(value: [Presentable], animated: Bool) -> Future<()>
	func pop(animated: Bool) -> Future<()>
	func go(to: Presentable, animated: Bool) -> Future<()>
}

public typealias Presenter = ModalPresenter & StructuredPresenter
