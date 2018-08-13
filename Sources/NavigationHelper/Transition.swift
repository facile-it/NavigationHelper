import Abstract
import FunctionalKit
import RxSwift

public struct Transition: Hashable {
	public let category: Category
	public let animation: Bool?
    
	public enum Category {
		case resetTo([Presentable])
		case modalPresent(Presentable)
		case moveTo(Presentable)
		case dismiss(all: Bool)
	}
}

extension Optional: Hashable where Wrapped: Hashable {
    public var hashValue: Int {
        return toArray().reduce(5381) {
            ($0 << 5) &+ $0 &+ $1.hashValue
        }
    }
}

extension Transition.Category: Hashable {
    public var hashValue: Int {
        switch self {
        case let .resetTo(presentables):
            return presentables.map { $0.hashable }.reduce(5381) {
                ($0 << 5) &+ $0 &+ $1.hashValue
            }
        case let .modalPresent(presentable):
            return presentable.hashable.hashValue
        case let .moveTo(presentable):
            return presentable.hashable.hashValue
        case let .dismiss(all: value):
            return value.hashValue
        }
    }
}

// MARK: - Public

extension Transition {
	public static func delegatingAnimation(_ category: Category) -> Transition {
		return Transition.init(category: category, animation: nil)
	}

	public static func animated(_ category: Category) -> Transition {
		return Transition.init(category: category, animation: true)
	}

	public static func nonAnimated(_ category: Category) -> Transition {
		return Transition.init(category: category, animation: false)
	}
}

extension Transition: Equatable {
	public static func == (lhs: Transition, rhs: Transition) -> Bool {
		return lhs.category == rhs.category
			&& lhs.animation == rhs.animation
	}
}

extension Transition.Category: Equatable {
	public static func == (lhs: Transition.Category, rhs: Transition.Category) -> Bool {
		switch (lhs, rhs) {

		case (.resetTo(let leftValue), .resetTo(let rightValue)):
			guard leftValue.count == rightValue.count else { return false }
			return zip(leftValue,rightValue).lazy
				.map { $0.isEqual(to: $1) }
				.map(And.init(_:))
				.concatenated().unwrap

		case (.modalPresent(let leftValue), .modalPresent(let rightValue)):
			return leftValue.isEqual(to: rightValue)

		case (.moveTo(let leftValue), .moveTo(let rightValue)):
			return leftValue.isEqual(to: rightValue)

		case (.dismiss(let leftValue),.dismiss(let rightValue)):
			return leftValue == rightValue

		default:
			return false
		}
	}
}

extension Transition: Executable {
	public typealias Context = AnyPresenter

	public var execution: Reader<AnyPresenter, Future<()>> {
		return Reader<AnyPresenter, Future<()>>.init { [animation, category] presenter in
			let animated = animation ?? presenter.shouldAnimate

			switch category {

			case .resetTo(let presentables):
				return presenter.resetTo(animated: animated).run(presentables)

			case .modalPresent(let presentable):
				return presenter.show(animated: animated).run(presentable)

			case .moveTo(let presentable):
				return presenter.moveTo(animated: animated).run(presentable)

			case .dismiss(let all) where presenter.currentModalPresented.isNil.not:
				return all.fold(
					onTrue: presenter.hideAll(animated: animated),
					onFalse: presenter.hide(animated: animated))

			case .dismiss(let all) where presenter.allStructuredPresented.isEmpty.not:
				return all.fold(
					onTrue: presenter.resetTo(animated: animated).run([]),
					onFalse: presenter.dropLast(animated: animated))

			default:
				return .pure(())
			}
		}
	}
}
