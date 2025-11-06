import UIKit
@testable import FreeCell

final class MockUIView: UIView {
    static var duration: TimeInterval = 0
    static var delay: TimeInterval = 0
    static var options: UIView.AnimationOptions = []
    static var animations: (() -> Void)? = nil
    static var completion: ((Bool) -> Void)? = nil
    static var view: UIView? = nil
    static var methodsCalled = [String]()

    static func reset() {
        duration = 0
        delay = 0
        options = []
        animations = nil
        completion = nil
        view = nil
        methodsCalled = []
    }

    override static func transition(
        with view: UIView,
        duration: TimeInterval,
        options: UIView.AnimationOptions = [],
        animations: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.view = view
        self.duration = duration
        self.options = options
        self.animations = animations
        self.completion = completion
        animations?()
        completion?(true)
        methodsCalled.append(#function)
    }

    override static func transitionAsync(
        with view: UIView,
        duration: Double,
        options: UIView.AnimationOptions,
        animations: (() -> Void)?
    ) async {
        methodsCalled.append(#function)
        await super.transitionAsync(
            with: view,
            duration: duration,
            options: options,
            animations: animations
        )
    }

    override static func animate(
        withDuration duration: TimeInterval,
        delay: TimeInterval,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.duration = duration
        self.delay = delay
        self.options = options
        self.animations = animations
        self.completion = completion
        animations()
        completion?(true)
        methodsCalled.append(#function)
    }

    override static func animateAsync(
        withDuration duration: Double,
        delay: Double,
        options: UIView.AnimationOptions,
        animations: @escaping () -> Void
    ) async {
        methodsCalled.append(#function)
        await super.animateAsync(
            withDuration: duration,
            delay: delay,
            options: options,
            animations: animations
        )
    }
}
