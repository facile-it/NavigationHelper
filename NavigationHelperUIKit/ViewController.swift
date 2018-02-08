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

			if let lastModalPresented = self.lastModalPresented, let shownPresenter = lastModalPresented as? ModalPresenter {
				return shownPresenter.show(animated: animated).run(presentable)
			}

			return Future<()>.unfold { done in
				DispatchQueue.main.async {
					self.present(viewController, animated: animated, completion: done)
				}
			}.start()
		}
	}

	public func hide(animated: Bool) -> Future<()> {
		if let lastModalPresented = self.lastModalPresented, let shownPresenter = lastModalPresented as? ModalPresenter, shownPresenter.isPresenting {
			return shownPresenter.hide(animated: animated)
		}

		return Future<()>.unfold { done in
			DispatchQueue.main.async {
				self.dismiss(animated: animated, completion: done)
			}
		}.start()
	}

	public var lastModalPresented: Presentable? {
		return presentedViewController
	}
}
