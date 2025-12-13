import UIKit

/// Content view for the cell that displays speed.
class SpeedCellContentView: UIView, UIContentView {
    /// Order of items matters! Must match GameState.AnimationSpeed order.
    lazy var segmentedControl = UISegmentedControl(items: ["Fast", "Slow", "Glacial", "None"]).applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(nil, action: #selector(PrefsViewController.segmentedControlChanged), for: .valueChanged)
    }

    /// Boilerplate.
    var appliedConfiguration: SpeedCellContentConfiguration!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? SpeedCellContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }

    /// Boilerplate except for construction of the view's contents.
    init(configuration: SpeedCellContentConfiguration) {
        super.init(frame: .zero)

        addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // boilerplate
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Boilerplate, followed by application of the configuration properties to the interface.
    func apply(configuration newConfiguration: SpeedCellContentConfiguration) {
        guard appliedConfiguration != newConfiguration else { return }
        appliedConfiguration = newConfiguration
        let speed = newConfiguration.speed
        let index = GameState.AnimationSpeed.allCases.firstIndex(of: speed) ?? 3
        if segmentedControl.selectedSegmentIndex != index {
            segmentedControl.selectedSegmentIndex = index
        }
    }
}

/// UIContentConfiguration for the speed cell.
struct SpeedCellContentConfiguration: UIContentConfiguration, Equatable {
    // settable properties
    var speed: GameState.AnimationSpeed

    // boilerplate

    func makeContentView() -> any UIView & UIContentView {
        return SpeedCellContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}
