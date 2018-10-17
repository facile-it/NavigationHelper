import UIKit
import NavigationHelper
import FunctionalKit

extension UISplitViewController: ModalPresenter {
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

extension UISplitViewController: StructuredPresenter {
    public var shouldAnimate: Bool {
        return isCollapsed
    }

    public var allStructuredPresented: [Presentable] {
        switch (self.masterNavController, self.detailNavController) {
        case (let master?, let detail?):
            return master.viewControllers + detail.viewControllers
        case (let master?, nil):
            return master.viewControllers
        case (nil, let detail?):
            return detail.viewControllers
        case (nil, nil):
            return []
        }
    }

    public func resetTo(animated: Bool) -> Reader<[Presentable], Future<Void>> {
        return Reader<[Presentable], Future<Void>>.init { presentables in
            return Future<Void> { [weak self] done in
                guard let this = self else { return }

                DispatchQueue.main.async {
                    let (master, detail) = this.prepareWithNavControllers()
                    if this.isCollapsed {
                        master.resetTo(animated: animated).run(presentables).start()
                    } else {
                        guard let (head, tail) = presentables.decomposed() else { done(()); return }

                        master.resetTo(animated: animated).run([head]).start()
                        detail.resetTo(animated: animated).run(Array(tail)).start()
                    }
                    guard animated else { done(()); return }
                    guard let transitionCoordinator = this.transitionCoordinator else { done(()); return }
                    transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
                }
                }
                .start()
        }
    }

    public func moveTo(animated: Bool) -> Reader<Presentable, Future<Void>> {
        return Reader<Presentable, Future<Void>>.init { presentable in
            return Future<Void> { [weak self] done in
                guard let this = self else { return }
                DispatchQueue.main.async {
                    let (master, detail) = this.prepareWithNavControllers()
                    if this.isCollapsed {
                        master.moveTo(animated: animated).run(presentable).start()
                    } else {
                        detail.moveTo(animated: animated).run(presentable).start()
                    }
                    guard animated else { done(()); return }
                    guard let transitionCoordinator = this.transitionCoordinator else { done(()); return }
                    transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
                }
                }
                .start()
        }
    }

    public func dropLast(animated: Bool) -> Future<Void> {
        guard allStructuredPresented.isEmpty.not else { return .pure(()) }

        return Future<Void> { [weak self] done in
            guard let this = self else { return }
            DispatchQueue.main.async {
                let (master, detail) = this.prepareWithNavControllers()
                if this.isCollapsed || this.traitCollection.horizontalSizeClass == .compact {
                    master.dropLast(animated: animated).start()
                } else {
                    if detail.allStructuredPresented.isEmpty.not {
                        detail.dropLast(animated: animated).start()
                    } else {
                        master.dropLast(animated: animated).start()
                    }
                }
                guard animated else { done(()); return }
                guard let transitionCoordinator = this.transitionCoordinator else { done(()); return }
                transitionCoordinator.animate(alongsideTransition: nil) { _ in done(()) }
            }
            }
            .start()
    }
}

extension UISplitViewController: TransitionHandlerOwner {
    public var transitionHandler: TransitionHandler {
        return TransitionHandler(context: AnyPresenter(self))
    }
}

// MARK: - PRIVATE

private extension UISplitViewController {
    var masterNavController: UINavigationController? {
        return viewControllers.getSafely(at: 0) as? UINavigationController
    }

    var detailNavController: UINavigationController? {
        return viewControllers.getSafely(at: 1) as? UINavigationController
    }

    @discardableResult
    func createMasterNavControllerIfNeeded() -> UINavigationController {
        if let master = self.masterNavController {
            return master
        } else {
            let navController = UINavigationController()
            self.viewControllers = [navController]
            return navController
        }
    }

    @discardableResult
    func createDetailNavControllerIfNeeded() -> UINavigationController {
        guard self.isCollapsed.not else {
            return createMasterNavControllerIfNeeded()
        }
        if let detail = self.detailNavController {
            return detail
        } else {
            let navController = UINavigationController()
            self.viewControllers = [
                createMasterNavControllerIfNeeded(),
                navController
            ]
            return navController
        }
    }

    func prepareWithNavControllers() -> (master: UINavigationController, detail: UINavigationController) {
        return (master: createMasterNavControllerIfNeeded(),
                detail: createDetailNavControllerIfNeeded())
    }
}
