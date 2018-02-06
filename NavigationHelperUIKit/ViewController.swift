import UIKit
import NavigationHelper
import FunctionalKit

extension UIViewController: Presentable {
	public var hashable: AnyHashable {
		return AnyHashable.init(self)
	}
}

extension Presentable {
	public var asViewController: UIViewController? {
		return self as? UIViewController
	}
}

extension SerialHandler where Message.Context: Presenter {
	public var rootViewController: UIViewController? {
		return context as? UIViewController
	}
}

extension UIViewController: ModalPresenter {
	public func show(animated: Bool) -> Reader<Presentable, Future<()>> {
		return Reader<Presentable, Future<()>>.unfold { presentable in
			guard let viewController = presentable.asViewController else { return .pure(()) }

			return Future<()>.unfold { done in
				DispatchQueue.main.async {
					self.present(viewController, animated: animated, completion: done)
				}
			}.start()
		}
	}

	public func hide(animated: Bool) -> Future<()> {
		return Future<()>.unfold { done in
			DispatchQueue.main.async {
				self.dismiss(animated: animated, completion: done)
			}
		}.start()
	}

	public var lastPresented: Presentable? {
		return presentedViewController
	}
}
