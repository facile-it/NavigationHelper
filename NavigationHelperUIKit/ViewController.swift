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
