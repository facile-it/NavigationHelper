import FunctionalKit
import RxSwift

public final class SerialHandler<Message> where Message: Hashable & Executable {
	private let messageSubject = PublishSubject<Message>()
    private var safetyRestartSubscribtion: Disposable? = nil
    
    private var inbox = [Message]() {
        didSet {
            if let last = inbox.last {
                Log.serialHandler("inbox: add \(last)")
            } else {
                Log.serialHandler("inbox: empty")
            }
        }
    }
    private var state = State.idle {
        didSet {
            Log.serialHandler("state: \(state)")
        }
    }
	public let context: Message.Context

    public var interMessageDelay: TimeInterval = 0
    public var safetyRestartDelay: TimeInterval = 3

    public init(context: Message.Context) {
		self.context = context
        Log.serialHandler("inbox: empty")
        Log.serialHandler("state: \(state)")
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
        Log.serialHandler("received: \(message)")
        
        let targetHashValue = message.hashValue

        return Future<Message> { done in
            Log.serialHandler("started: \(message)")

            self.disposables[targetHashValue] = self.messageSubject
                .filter { incoming in
                    incoming.hashValue == targetHashValue
                }
                .subscribe(onNext: { [weak self] incoming in
                    
                    Log.serialHandler("completed: \(message)")
                    
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
    private func restart() {
        Log.serialHandler("SAFETY RESTART")

        safetyRestartSubscribtion?.dispose()
        safetyRestartSubscribtion = nil
        state = .idle
        handleNext()
    }
    
	private func handleNext() {
		guard case .idle = state, inbox.isEmpty.not else {
            Log.serialHandler("ignore handleNext (state: \(state), inbox: \(inbox))")
            return
        }

		state = .working

        safetyRestartSubscribtion?.dispose()
        safetyRestartSubscribtion = Observable.just(())
            .delay(safetyRestartDelay, scheduler: SerialDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.restart()
            })
        
		let message = inbox.removeFirst()
        
        Log.serialHandler("handling: \(message)")
        
		message.execution.run(context).run { [weak self] in
			guard let self = self else { return }
            
            Log.serialHandler("executed: \(message)")

			self.messageSubject.on(.next(message))

            let nextExecution = {
                self.state = .idle
                self.handleNext()
            }

            if self.interMessageDelay > 0 {
                DispatchQueue.global(qos: .userInteractive).asyncAfter(
                    deadline: .now() + self.interMessageDelay,
                    execute: nextExecution)
            } else {
                nextExecution()
            }
		}
	}
}
