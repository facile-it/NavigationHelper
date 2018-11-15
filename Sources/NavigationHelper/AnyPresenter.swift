import Foundation
import FunctionalKit

public final class AnyPresenter: Presenter {
    private let modalPresenter: ModalPresenter
    private let structuredPresenter: StructuredPresenter

    public init(modalPresenter: ModalPresenter, structuredPresenter: StructuredPresenter) {
        self.modalPresenter = modalPresenter
        self.structuredPresenter = structuredPresenter
    }

    public convenience init(_ presenter: Presenter) {
        self.init(modalPresenter: presenter, structuredPresenter: presenter)
    }

    public var shouldAnimate: Bool {
        return structuredPresenter.shouldAnimate
    }
    
    public var presentable: Presentable {
        return structuredPresenter.presentable
    }

    public var currentModalPresented: Presentable? {
        return modalPresenter.currentModalPresented
    }

    public func show(animated: Bool) -> Reader<Presentable, Future<Void>> {
        return modalPresenter.show(animated: animated)
    }

    public func hide(animated: Bool) -> Future<Void> {
        return modalPresenter.hide(animated: animated)
    }

    public var allStructuredPresented: [Presentable] {
        return structuredPresenter.allStructuredPresented
    }

    public func resetTo(animated: Bool) -> Reader<[Presentable], Future<Void>> {
        return structuredPresenter.resetTo(animated: animated)
    }

    public func moveTo(animated: Bool) -> Reader<Presentable, Future<Void>> {
        return structuredPresenter.moveTo(animated: animated)
    }

    public func dropLast(animated: Bool) -> Future<Void> {
        return structuredPresenter.dropLast(animated: animated)
    }
}
