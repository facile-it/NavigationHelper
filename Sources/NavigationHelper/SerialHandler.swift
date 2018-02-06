import FunctionalKit
import RxSwift

public final class SerialHandler<Message> where Message: Equatable & Executable {
	private let messageSubject = PublishSubject<Message>.init()
	private var inbox = [Message].init()
	private var state = State.idle
	private let disposeBag = DisposeBag()
	private let context: Message.Context

	public init(context: Message.Context) {
		self.context = context
	}

	enum State {
		case idle
		case working
	}
}

public typealias TransitionHandler = SerialHandler<Transition>

// MARK: - Public

extension SerialHandler {
	public func handle(_ message: Message) -> Future<Message> {
		return Future<Message>.unfold { done in
			self.messageSubject
				.filter { $0 == message }
				.subscribe(onNext: { message in
					done(message)
				})
				.disposed(by: self.disposeBag)

			self.inbox.append(message)
			self.handleNext()
		}
	}
}

// MARK: - Private

extension SerialHandler {
	private func handleNext() {
		guard case .idle = state, inbox.isEmpty.not else { return }

		state = .working
		let message = inbox.removeFirst()

		message.execution.run(context).run { [weak self] in
			guard let this = self else { return }
			this.messageSubject.on(.next(message))
			this.state = .idle
			this.handleNext()
		}
	}
}
