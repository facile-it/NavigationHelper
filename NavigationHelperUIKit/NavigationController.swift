import UIKit
import NavigationHelper
import FunctionalKit

extension UINavigationController: StructuredPresenter {
	public var allPresented: [Presentable] {
		return viewControllers
	}

	public func resetTo(animated: Bool) -> Reader<[Presentable], Future<()>> {
		return Reader<[Presentable], Future<()>>.unfold { presentables in
			Future<()>.unfold { done in
				let viewControllers = presentables.flatMap { $0.asViewController }
				self.setViewControllers(viewControllers, animated: animated)

				guard animated else { done(()); return }
				self.transitionCoordinator?.animate(alongsideTransition: nil) { _ in done(()) }
			}.start()
		}
	}

	public func moveTo(animated: Bool) -> Reader<Presentable, Future<()>> {
		return Reader<Presentable, Future<()>>.unfold { presentable in
			guard let viewController = presentable.asViewController else { return .pure(()) }

			return Future<()>.unfold { done in
				if self.viewControllers.contains(viewController) {
					self.popToViewController(viewController, animated: animated)
				} else {
					self.pushViewController(viewController, animated: animated)
				}

				guard animated else { done(()); return }
				self.transitionCoordinator?.animate(alongsideTransition: nil) { _ in done(()) }
			}.start()
		}
	}

	public func dropLast(animated: Bool) -> Future<()> {
		return Future<()>.unfold { done in
			guard
				self.viewControllers.isEmpty.not,
				self.popViewController(animated: animated).isNil.not,
				animated else { done(()); return }
			self.transitionCoordinator?.animate(alongsideTransition: nil) { _ in done(()) }
		}.start()
	}
}
