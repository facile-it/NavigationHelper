import UIKit
import NavigationHelper
import FunctionalKit

extension UISplitViewController: StructuredPresenter {
    public var shouldAnimate: Bool {
        return shouldBeCollapsed
    }

    public var allStructuredPresented: [Presentable] {
        Log.presenter("\(self): ask for allStructuredPresented")

        switch (self.masterNavController, self.detailNavController) {
        case (let master?, let detail?):
            Log.presenter("\(self): returning master(\(master.viewControllers)) and detail(\(detail.viewControllers))")
            return master.viewControllers + detail.viewControllers
        case (let master?, nil):
            Log.presenter("\(self): returning master(\(master.viewControllers))")
            return master.viewControllers
        case (nil, let detail?):
            Log.presenter("\(self): returning detail(\(detail.viewControllers))")
            return detail.viewControllers
        case (nil, nil):
            Log.presenter("\(self): returning no presentables")
            return []
        }
    }

    public func resetTo(animated: Bool) -> Reader<[Presentable], Future<Void>> {
        Log.presenter("\(self): ask to resetTo animated(\(animated))")

        return Reader<[Presentable], Future<Void>>.init { presentables in
            
            Log.presenter("\(self): should resetTo \(presentables)")

            return Future<Void> { done in
                DispatchQueue.main.async {
                    let (master, detail) = self.prepareWithNavControllers()
                    Log.presenter("\(self): will resetTo \(presentables)")

                    if self.shouldBeCollapsed {
                        Log.presenter("\(self): UI should be collapsed, master \(master) will resetTo \(presentables)")
                        master.resetTo(animated: animated).run(presentables).start()
                    } else {
                        guard let (head, tail) = presentables.decomposed() else { done(()); return }
                        Log.presenter("\(self): UI should not be collapsed, master \(master) will resetTo \(head), detail \(detail) will reset to \(tail)")

                        master.resetTo(animated: animated).run([head]).start()
                        detail.resetTo(animated: animated).run(Array(tail)).start()
                    }
                    guard animated else {
                        Log.presenter("\(self): done resetTo without animation")

                        done(())
                        return
                    }
                    guard let transitionCoordinator = self.transitionCoordinator else {
                        Log.presenter("\(self): done resetTo without animation")

                        done(())
                        return
                    }
                    transitionCoordinator.animate(alongsideTransition: nil) { _ in
                        Log.presenter("\(self): done resetTo with animation")

                        done(())
                    }
                }
                }.start()
        }
    }

    public func moveTo(animated: Bool) -> Reader<Presentable, Future<Void>> {
        Log.presenter("\(self): ask to moveTo animated(\(animated))")

        return Reader<Presentable, Future<Void>>.init { presentable in
            Log.presenter("\(self): should moveTo \(presentable)")

            return Future<Void> { done in
                DispatchQueue.main.async {
                    Log.presenter("\(self): will moveTo \(presentable)")

                    let (master, detail) = self.prepareWithNavControllers()
                    if self.shouldBeCollapsed {
                        Log.presenter("\(self): UI should be collapsed, master \(master) will moveTo \(presentable)")
                        master.moveTo(animated: animated).run(presentable).start()
                    } else {
                        Log.presenter("\(self): UI should not be collapsed, detail \(detail) will moveTo \(presentable)")
                        detail.moveTo(animated: animated).run(presentable).start()
                    }
                    guard animated else {
                        Log.presenter("\(self): done moveTo without animation")

                        done(())
                        return
                    }
                    
                    guard let transitionCoordinator = self.transitionCoordinator else {
                        Log.presenter("\(self): done moveTo without animation")
                        done(())
                        return
                    }
                    
                    transitionCoordinator.animate(alongsideTransition: nil) { _ in
                        Log.presenter("\(self): done moveTo with animation")

                        done(())
                    }
                }
                }.start()
        }
    }

    public func dropLast(animated: Bool) -> Future<Void> {
        Log.presenter("\(self): ask to dropLast animated(\(animated))")

        guard allStructuredPresented.isEmpty.not else {
            Log.presenter("\(self): cannot dropLast for no structuredPresented")

            return .pure(())
        }
        
        return Future<Void> { done in
            DispatchQueue.main.async {
                Log.presenter("\(self): will dropLast")

                let (master, detail) = self.prepareWithNavControllers()
                if self.shouldBeCollapsed {
                    Log.presenter("\(self): UI should be collapsed, master \(master) will dropLast")

                    master.dropLast(animated: animated).start()
                } else {
                    if detail.allStructuredPresented.isEmpty.not {
                        Log.presenter("\(self): UI should not be collapsed, and detail has some structuredPresented, detail \(detail) will dropLast")

                        detail.dropLast(animated: animated).start()
                    } else {
                        Log.presenter("\(self): UI should not be collapsed, and detail has no structuredPresented, master \(master) will dropLast")

                        master.dropLast(animated: animated).start()
                    }
                }
                guard animated else {
                    Log.presenter("\(self): done dropLast without animation")

                    done(())
                    return
                }
                
                guard let transitionCoordinator = self.transitionCoordinator else {
                    Log.presenter("\(self): done dropLast without animation")

                    done(())
                    return
                }
                
                transitionCoordinator.animate(alongsideTransition: nil) { _ in
                    Log.presenter("\(self): done dropLast with animation")

                    done(())
                }
            }
            }.start()
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
    
    var shouldBeCollapsed: Bool {
        return isCollapsed || traitCollection.horizontalSizeClass == .compact
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
        guard self.shouldBeCollapsed.not else {
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
