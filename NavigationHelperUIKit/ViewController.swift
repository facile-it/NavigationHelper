import UIKit
import NavigationHelper
import FunctionalKit

extension UIViewController: Presentable {
	public var hashable: AnyHashable {
		return AnyHashable(self)
	}
}

extension Presentable {
	public var asViewController: UIViewController? {
		return self as? UIViewController
	}
}

extension UIViewController: ModalPresenter {
    public var presentable: Presentable {
        return self
    }
    
    public func show(animated: Bool) -> Reader<Presentable, Future<Void>> {
        Log.presenter("\(self): ask to show animated(\(animated))")
        
        return Reader<Presentable, Future<Void>>.init { presentable in
            guard let viewController = presentable.asViewController else { return .pure(()) }
            
            Log.presenter("\(self): should show \(viewController)")

            if let currentModalPresented = self.currentModalPresented, let shownPresenter = currentModalPresented as? ModalPresenter {
                Log.presenter("\(self): delegate show to \(shownPresenter)")
                return shownPresenter.show(animated: animated).run(presentable)
            }
            
            return Future<Void> { done in
                DispatchQueue.main.async {
                    Log.presenter("\(self): will show \(viewController)")

                    self.present(viewController, animated: animated, completion: { done(()) })
                }
                }.start()
        }
    }
    
    public func hide(animated: Bool) -> Future<Void> {
        Log.presenter("\(self): ask to hide animated(\(animated))")

        guard let currentModalPresented = self.currentModalPresented else {
            Log.presenter("\(self): no currentModalPresented, cannot hide")
            return .pure(())
        }
        
        if let shownPresenter = currentModalPresented as? ModalPresenter, shownPresenter.isPresenting {
            Log.presenter("\(self): delegate hide to \(shownPresenter)")
            return shownPresenter.hide(animated: animated)
        }
        
        return Future<Void> { done in
            DispatchQueue.main.async {
                Log.presenter("\(self): will hide")
                
                self.dismiss(animated: animated, completion: { done(()) })
            }
            }.start()
    }

    public var currentModalPresented: Presentable? {
        return presentedViewController
    }
}
