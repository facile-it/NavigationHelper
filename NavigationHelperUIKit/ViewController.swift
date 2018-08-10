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

extension UIViewController: ModalPresenter {
	public func show(animated: Bool) -> Reader<Presentable, Future<()>> {
		return Reader<Presentable, Future<()>>.init { presentable in
			guard let viewController = presentable.asViewController else { return .pure(()) }

			if let currentModalPresented = self.currentModalPresented, let shownPresenter = currentModalPresented as? ModalPresenter {
				return shownPresenter.show(animated: animated).run(presentable)
			}

			return Future<()>
				.init { done in
					DispatchQueue.main.async {
						self.present(viewController, animated: animated, completion: done)
					}
				}
				.start()
		}
	}

	public func hide(animated: Bool) -> Future<()> {
		guard let currentModalPresented = self.currentModalPresented else { return .pure(()) }

		if let shownPresenter = currentModalPresented as? ModalPresenter, shownPresenter.isPresenting {
			return shownPresenter.hide(animated: animated)
		}

		return Future<()>
			.init { done in
				DispatchQueue.main.async {
					self.dismiss(animated: animated, completion: done)
				}
			}
			.start()
	}

	public var currentModalPresented: Presentable? {
		return presentedViewController
	}
}
