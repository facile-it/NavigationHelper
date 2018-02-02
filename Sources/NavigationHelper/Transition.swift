import Abstract
import FunctionalKit

public struct Transition {
	public var category: Category
	public var animation: Bool

	public enum Category {
		case reset([Presentable])
		case modalPresent(Presentable)
		case structuredPresent([Presentable])
		case goTo(Presentable)
		case dismiss
	}
}

// MARK: - Public

extension Transition {
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

		case (.modalPresent(let leftValue), .modalPresent(let rightValue)):
			return leftValue.hashable == rightValue.hashable

		case (.structuredPresent(let leftValue), .structuredPresent(let rightValue)):
			guard leftValue.count == rightValue.count else { return false }
			return zip(leftValue,rightValue).lazy
				.map { $0.hashable == $1.hashable }
				.map(And.init(_:))
				.concatenated.unwrap

		case (.goTo(let leftValue), .goTo(let rightValue)):
			return leftValue.hashable == rightValue.hashable

		case (.dismiss,.dismiss):
			return true

		default:
			return false
		}
	}
}

extension Transition: Executable {
	public typealias Context = Presenter

	public var execution: Reader<Presenter, Future<()>> {
		return .unfold { presenter in
			switch self.category {

			case .reset(let presentables):
				return presenter.reset(value: presentables, animated: self.animation)

			case .modalPresent(let presentable):
				return presenter.present(value: presentable, animated: self.animation)

			case .structuredPresent(let presentables):
				return presenter.push(value: presentables, animated: self.animation)

			case .goTo(let presentable):
				return presenter.go(to: presentable, animated: self.animation)

			case .dismiss where presenter.lastPresented.isNil.not:
				return presenter.dismiss(animated: self.animation)

			case .dismiss where presenter.allPresented.isEmpty.not:
				return presenter.pop(animated: self.animation)

			default:
				return .pure(())
			}
		}
	}
}
