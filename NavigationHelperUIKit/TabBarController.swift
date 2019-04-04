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
    
    public func resetTo(animated: Bool) -> Reader<[Presentable], Future<Void>> {
        Log.presenter("\(self): ask to resetTo animated(\(animated))")
        
        return Reader<[Presentable], Future<Void>>.init { presentables in
            let viewControllers = presentables.compactMap { $0.asViewController }
            
            Log.presenter("\(self): should resetTo \(viewControllers)")
            
            return Future<Void> { done in
                DispatchQueue.main.async {
                    Log.presenter("\(self): will resetTo \(viewControllers)")
                    
                    self.setViewControllers(viewControllers, animated: animated)
                    
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
            guard let viewController = presentable.asViewController else { return .pure(()) }
            
            Log.presenter("\(self): should moveTo \(viewController)")
            
            return Future<Void> { done in
                DispatchQueue.main.async {
                    Log.presenter("\(self): will moveTo \(viewController)")
                    
                    if let index = self.viewControllers?.firstIndex(of: viewController) {
                        Log.presenter("\(self): index(\(index)) for \(viewController) is present, selecting")
                        
                        self.selectedIndex = index
                        done(())
                    } else {
                        Log.presenter("\(self): adding \(viewController) and selecting")
                        
                        self.setViewControllers(self.viewControllers.get(or: []) + [viewController], animated: animated)
                        self.selectedViewController = viewController
                        
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
                
                guard let viewControllers = self.viewControllers, viewControllers.isEmpty.not else {
                    Log.presenter("\(self): no view controller to drop")
                    
                    done(())
                    return
                }
                
                self.setViewControllers(Array(viewControllers.dropLast()), animated: animated)
                
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

extension UITabBarController: TransitionHandlerOwner {
    public var transitionHandler: TransitionHandler {
        return TransitionHandler(context: AnyPresenter(self))
    }
}
