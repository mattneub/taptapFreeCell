import UIKit

/// Type alias just to make the protocol declaration a little shorter
typealias PageViewControllerDatasourceDelegate = AnyObject & UIPageViewControllerDataSource & UIPageViewControllerDelegate

/// Protocol describing a type that functions as the data source and delegate of a page view
/// controller. Basically, in addition to being a data source and delegate, it needs to be handed
/// a reference to its page view controller, it needs a reference to its processor, it needs
/// an established place to store the data, and it is a Receiver so that it can be sent effects
/// as commands.
protocol PageViewControllerDatasourceType<ProcessorActionType, EffectType, StateType, DataType>: PageViewControllerDatasourceDelegate {
    associatedtype ProcessorActionType
    associatedtype EffectType
    associatedtype DataType
    associatedtype StateType

    var processor: (any Receiver<ProcessorActionType>)? { get set }

    init(pageViewController: UIPageViewController, processor: (any Receiver<ProcessorActionType>)?)

    var data: [DataType] { get set }

    func present(_: StateType) async

    func receive(_: EffectType) async
}
