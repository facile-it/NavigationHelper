import FunctionalKit
import RxSwift

public final class SerialHandler<Message> where Message: Hashable & Executable {
	private let messageSubject = PublishSubject<Message>()
	private var inbox = [Message]()
	private var state = State.idle
	public let context: Message.Context

    public var interMessageDelay: Double = 0

    public init(context: Message.Context) {
		self.context = context
	}

	enum State {
		case idle
		case working
	}
    
    private var disposables: [Int: Disposable] = [:]
}

public typealias TransitionHandler = SerialHandler<Transition>

// MARK: - Public

extension SerialHandler: TransitionHandlerType where Message == Transition {}

extension SerialHandler {
	public func handle(_ message: Message) -> Future<Message> {
        let targetHashValue = message.hashValue

        return Future<Message> { done in
            self.disposables[targetHashValue] = self.messageSubject
                .filter { incoming in
                    incoming.hashValue == targetHashValue
                }
                .subscribe(onNext: { [weak self] incoming in
                    done(incoming)
                    self?.disposables[targetHashValue]?.dispose()
                    self?.disposables[targetHashValue] = nil
                })

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

            let nextExecution = {
                this.state = .idle
                this.handleNext()
            }

            if this.interMessageDelay > 0 {
                DispatchQueue.global(qos: .userInteractive).asyncAfter(
                    deadline: .now() + this.interMessageDelay,
                    execute: nextExecution)
            } else {
                nextExecution()
            }
		}
	}
}
