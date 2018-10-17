import UIKit
import NavigationHelper
import FunctionalKit
import Abstract

extension UITabBarController: StructuredPresenter {
	public var shouldAnimate: Bool {
		return true
	}

	public var allStructuredPresented: [Presentable] {
		return viewControllers.get(or: [])
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
						if let index = self.viewControllers?.index(of: viewController) {
							self.selectedIndex = index
							done(())
						} else {
							self.setViewControllers(self.viewControllers.get(or: []) + [viewController], animated: animated)
							self.selectedViewController = viewController
							guard animated else { done(()); return }
							guard let transitionCoordinator = self.transitionCoordinator else { done(()); return }
							transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
						}
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
					guard let viewControllers = self.viewControllers, viewControllers.isEmpty.not else { done(()); return }
					self.setViewControllers(viewControllers.dropLast() |> Array.init(_:), animated: animated)
					guard animated else { done(()); return }
					guard let transitionCoordinator = self.transitionCoordinator else { done(()); return }
					transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
				}
			}
			.start()
	}
}

extension UITabBarController {
	public var transitionHandler: TransitionHandler {
		return TransitionHandler.init(context: AnyPresenter.init(self))
	}
}
