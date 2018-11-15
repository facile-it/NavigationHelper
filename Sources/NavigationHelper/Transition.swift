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
        case custom(hashValue: Int, present: (Presenter) -> Future<()>)
	}
}

extension Transition.Category: Hashable {
    public var hashValue: Int {
        switch self {
        case let .resetTo(presentables):
            return presentables
                .reduce(into: Hasher()) { currentHasher, presentable in
                    currentHasher.combine(presentable.hashable)
                }
                .finalize()
        case let .modalPresent(presentable):
            return presentable.hashable.hashValue
        case let .moveTo(presentable):
            return presentable.hashable.hashValue
        case let .dismiss(all: value):
            return value.hashValue
        case .custom(let hashValue, _):
            return hashValue
        }
    }
}

extension Transition {
	public enum lens {
		public static let category = Lens<Transition, Transition.Category>(
			get: { $0.category },
			set: { part in
				{ whole in
					Transition(
						category: part,
						animation: whole.animation)
				}
		})

		public static let animation = Lens<Transition, Bool?>(
			get: { $0.animation },
			set: { part in
				{ whole in
					Transition(
						category: whole.category,
						animation: part)
				}
		})
	}
}

extension Transition.Category {
	public enum prism {
		public static let resetTo = Prism<Transition.Category, [Presentable]>(
			tryGet: {
				guard case let .resetTo(value) = $0 else { return nil }
				return value
		},
			inject: Transition.Category.resetTo)

		public static let modalPresent = Prism<Transition.Category, Presentable>(
			tryGet: {
				guard case let .modalPresent(value) = $0 else { return nil }
				return value
		},
			inject: Transition.Category.modalPresent)

		public static let moveTo = Prism<Transition.Category, Presentable>(
			tryGet: {
				guard case let .moveTo(value) = $0 else { return nil }
				return value
		},
			inject: Transition.Category.moveTo)

		public static let dismiss = Prism<Transition.Category, Bool>(
			tryGet: {
				guard case let .dismiss(value) = $0 else { return nil }
				return value
		},
			inject: Transition.Category.dismiss)
        
        public static let custom = Prism<Transition.Category, (Int, (Presenter) -> Future<()>)>(
            tryGet: {
                guard case .custom(let hashValue, let presentationFunction) = $0 else { return nil }
                return (hashValue, presentationFunction)
        },
            inject: { Transition.Category.custom(hashValue: $0, present: $1) })
	}
}

// MARK: - Public

extension Transition {
	public static func delegatingAnimation(_ category: Category) -> Transition {
		return Transition(category: category, animation: nil)
	}

	public static func animated(_ category: Category) -> Transition {
		return Transition(category: category, animation: true)
	}

	public static func nonAnimated(_ category: Category) -> Transition {
		return Transition(category: category, animation: false)
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
            
        case (.custom(let leftValue, _), .custom(let rightValue, _)):
            return leftValue == rightValue

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
                
            case .custom(_, let present):
                return present(presenter)
                
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
