import FunctionalKit
import RxSwift
import Foundation

public final class SerialHandler<Message>: CustomStringConvertible where Message: Hashable & Executable {
	private let messageSubject = PublishSubject<Message>()
    private var safetyRestartSubscribtion: Disposable? = nil
    
    private var inbox = [Message]() {
        didSet {
            if let last = inbox.last {
                Log.serialHandler("\(self): inbox: add \(last)")
            } else {
                Log.serialHandler("\(self): inbox: empty")
            }
        }
    }
    private var state = State.idle {
        didSet {
            Log.serialHandler("\(self): state: \(state)")
        }
    }
	public let context: Message.Context
    public let identifier: String

    public var interMessageDelay: TimeInterval = 0
    public var safetyRestartDelay: DispatchTimeInterval = .seconds(3)

    public init(context: Message.Context, identifier: String? = nil) {
		self.context = context
        self.identifier = identifier ?? "on(\(context))"
        
        Log.serialHandler("\(self): START")
        Log.serialHandler("\(self): inbox: empty")
        Log.serialHandler("\(self): state: \(state)")
	}
    
    public var description: String {
        return identifier
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
        Log.serialHandler("\(self): received: \(message)")
        
        let targetHashValue = message.hashValue

        return Future<Message> { done in
            Log.serialHandler("\(self): started: \(message)")

            self.disposables[targetHashValue] = self.messageSubject
                .filter { incoming in
                    incoming.hashValue == targetHashValue
                }
                .subscribe(onNext: { [weak self] incoming in
                    
                    if let self = self {
                        Log.serialHandler("\(self): completed: \(message)")
                    } else {
                        Log.serialHandler("DEALLOCATED: completed: \(message)")
                    }
                    
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
        safetyRestartSubscribtion?.dispose()
        safetyRestartSubscribtion = nil
        
        if state != .idle {
            Log.serialHandler("\(self): SAFETY RESTART")
            state = .idle
            handleNext()
        }
    }
    
	private func handleNext() {
		guard case .idle = state, inbox.isEmpty.not else {
            Log.serialHandler("\(self): ignore handleNext (state: \(state), inbox: \(inbox))")
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
        
        Log.serialHandler("\(self): handling: \(message)")
        
		message.execution.run(context).run { [weak self] in
			guard let self = self else { return }
            
            Log.serialHandler("\(self): executed: \(message)")

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
