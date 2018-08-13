import FunctionalKit
import RxSwift

public final class SerialHandler<Message> where Message: Equatable & Executable & Disposer {
	private let messageSubject = PublishSubject<Message>.init()
	private var inbox = [Message]()
	private var state = State.idle
	public let context: Message.Context

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
		return Future<Message> { [weak self] done in
            guard let this = self else { return }
			
            this.messageSubject
				.filter { [weak message] incoming in
                    incoming == message
                }
				.subscribe(onNext: { incoming in
					done(incoming)
				})
				.disposed(by: message.bag)

			this.inbox.append(message)
			this.handleNext()
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
