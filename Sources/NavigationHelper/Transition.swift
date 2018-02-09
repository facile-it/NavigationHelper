import Abstract
import FunctionalKit

public struct Transition {
	public var category: Category
	public var animation: Bool

	public enum Category {
		case resetTo([Presentable])
		case modalPresent(Presentable)
		case moveTo(Presentable)
		case dismiss(all: Bool)
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

		case (.resetTo(let leftValue), .resetTo(let rightValue)):
			guard leftValue.count == rightValue.count else { return false }
			return zip(leftValue,rightValue).lazy
				.map { $0.isEqual(to: $1) }
				.map(And.init(_:))
				.concatenated.unwrap

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
		return .unfold { presenter in
			switch self.category {

			case .resetTo(let presentables):
				return presenter.resetTo(animated: self.animation).run(presentables)

			case .modalPresent(let presentable):
				return presenter.show(animated: self.animation).run(presentable)

			case .moveTo(let presentable):
				return presenter.moveTo(animated: self.animation).run(presentable)

			case .dismiss(let all) where presenter.lastModalPresented.isNil.not:
				return all.fold(
					onTrue: presenter.hideAll(animated: self.animation),
					onFalse: presenter.hide(animated: self.animation))

			case .dismiss(let all) where presenter.allStructuredPresented.isEmpty.not:
				return all.fold(
					onTrue: presenter.resetTo(animated: self.animation).run([]),
					onFalse: presenter.dropLast(animated: self.animation))

			default:
				return .pure(())
			}
		}
	}
}
