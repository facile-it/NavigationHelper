import UIKit
import NavigationHelper
import FunctionalKit

extension UINavigationController: StructuredPresenter {
	public var shouldAnimate: Bool {
		return true
	}

	public var allStructuredPresented: [Presentable] {
		return viewControllers
	}

	public func resetTo(animated: Bool) -> Reader<[Presentable], Future<()>> {
		return Reader<[Presentable], Future<()>>.init { presentables in
			Future<()>
				.init { done in
					DispatchQueue.main.async {
						let viewControllers = presentables.compactMap { $0.asViewController }
						self.setViewControllers(viewControllers, animated: animated)

						guard animated else { done(()); return }
						guard let transitionCoordinator = self.transitionCoordinator else { done(()); return }
						transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
					}
				}
				.start()
		}
	}

	public func moveTo(animated: Bool) -> Reader<Presentable, Future<()>> {
		return Reader<Presentable, Future<()>>.init { presentable in
			guard let viewController = presentable.asViewController else { return .pure(()) }

			return Future<()>
				.init { done in
					DispatchQueue.main.async {
						if self.viewControllers.contains(viewController) {
							self.popToViewController(viewController, animated: animated)
						} else {
							self.pushViewController(viewController, animated: animated)
						}
						
						guard animated else { done(()); return }
						guard let transitionCoordinator = self.transitionCoordinator else { done(()); return }
						transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
					}
				}
				.start()
		}
	}

	public func dropLast(animated: Bool) -> Future<()> {
		guard allStructuredPresented.isEmpty.not else { return .pure(()) }

		return Future<()>
			.init { done in
				DispatchQueue.main.async {
					guard
						self.popViewController(animated: animated).isNil.not,
						animated else { done(()); return }
					guard let transitionCoordinator = self.transitionCoordinator else { done(()); return }
					transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
				}
			}
			.start()
	}
}

extension UINavigationController {
	public var transitionHandler: TransitionHandler {
		return TransitionHandler.init(context: AnyPresenter.init(self))
	}
}
