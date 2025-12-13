import UIKit

/// Content view for the cell that displays a pref.
class PrefCellContentView: UIView, UIContentView {

    lazy var prefLabel = UILabel().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = UIFont.systemFont(ofSize: 17)
    }

    lazy var prefSwitch = PrefSwitch().applying {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.addTarget(nil, action: #selector(PrefsViewController.prefSwitchChanged), for: .valueChanged)
    }

    /// Boilerplate.
    var appliedConfiguration: PrefCellContentConfiguration!

    /// Boilerplate.
    var configuration: any UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? PrefCellContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }

    /// The left constraint on the label. This is separated out into a property so we can adjust
    /// its constant depending on whether this is a subordinate pref.
    var labelLeftConstraint: NSLayoutConstraint?

    /// Boilerplate except for construction of the view's contents.
    init(configuration: PrefCellContentConfiguration) {
        super.init(frame: .zero)

        addSubview(prefLabel)
        NSLayoutConstraint.activate([
            prefLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        labelLeftConstraint = prefLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8).activate()
        addSubview(prefSwitch)
        NSLayoutConstraint.activate([
            prefSwitch.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            prefSwitch.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // boilerplate
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Boilerplate, followed by application of the configuration properties to the interface.
    func apply(configuration newConfiguration: PrefCellContentConfiguration) {
        guard appliedConfiguration != newConfiguration else { return }
        appliedConfiguration = newConfiguration
        if prefLabel.text != newConfiguration.text {
            prefLabel.text = newConfiguration.text
        }
        if prefSwitch.isOn != newConfiguration.value {
            let animated = prefSwitch.prefKey != nil
            prefSwitch.setOn(newConfiguration.value, animated: animated)
        }
        if prefSwitch.prefKey != newConfiguration.prefKey {
            prefSwitch.prefKey = newConfiguration.prefKey
        }
        labelLeftConstraint?.constant = newConfiguration.isSubordinate ? 24 : 8
    }
}

/// UIContentConfiguration for the pref cell.
struct PrefCellContentConfiguration: UIContentConfiguration, Equatable {
    // settable properties

    var text: String
    var value: Bool
    var isSubordinate: Bool
    var prefKey: PrefKey

    // boilerplate

    func makeContentView() -> any UIView & UIContentView {
        return PrefCellContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}

extension PrefCellContentConfiguration {
    /// Initializer from a pref.
    init(pref: Pref) {
        self.text = pref.key.rawValue
        self.value = pref.value
        self.isSubordinate = pref.key.isSubordinateTo != nil
        self.prefKey = pref.key
    }
}
