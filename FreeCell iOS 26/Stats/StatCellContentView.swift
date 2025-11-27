import UIKit

/// Content view for the cell that displays a stat.
class StatCellContentView: UIView, UIContentView {

    // outlets will be filled by loading the subview from a nib

    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var wonLabel : UILabel!
    @IBOutlet weak var movesLabel : UILabel!
    @IBOutlet weak var timeLabel : UILabel!
    @IBOutlet weak var supplementaryLabel: UILabel!

    /// Boilerplate.
    var appliedConfiguration: StatCellContentConfiguration!

    /// Boilerplate.
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? StatCellContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }

    /// This view (the StatCellContentView) is itself just a blank. It gets its content by
    /// loading it from a nib (thus also filling the outlets) and adding that content as subview.
    /// Boilerplate except how we obtain the loaded view.
    init(configuration: StatCellContentConfiguration) {
        super.init(frame: .zero)

        let topLevelObjects = UINib(nibName: "StatCell", bundle: nil).instantiate(withOwner: self)
        guard let loadedView = topLevelObjects.first as? UIView else { return }
        loadedView.backgroundColor = nil
        self.addSubview(loadedView)
        loadedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadedView.topAnchor.constraint(equalTo: topAnchor),
            loadedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            loadedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadedView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // boilerplate
        apply(configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Boilerplate, followed by application of the configuration properties to the interface.
    func apply(configuration newConfiguration: StatCellContentConfiguration) {
        guard appliedConfiguration != newConfiguration else { return }
        appliedConfiguration = newConfiguration
        dateLabel.text = (
            newConfiguration.date.formatted(date: .numeric, time: .omitted) +
            "\n" +
            newConfiguration.date.formatted(date: .omitted, time: .shortened)
        )
        wonLabel.text = newConfiguration.won ? "✅" : "🚫"
        movesLabel.text = newConfiguration.won ? String(newConfiguration.movesCount) + " moves" : ""
        timeLabel.text = Stopwatch.timeTakenFormatter.string(from: newConfiguration.time)
        supplementaryLabel.text = nil
    }
}

/// UIContentConfiguration for the stat cell.
struct StatCellContentConfiguration: UIContentConfiguration, Equatable {
    // settable properties

    var date: Date
    var won: Bool
    var movesCount: Int
    var time: TimeInterval

    // boilerplate

    func makeContentView() -> any UIView & UIContentView {
        return StatCellContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> Self {
        return self
    }
}

extension StatCellContentConfiguration {
    /// Initializer from a stat.
    init(stat: Stat) {
        self.date = stat.dateFinished
        self.won = stat.won
        self.movesCount = stat.movesCount
        self.time = stat.timeTaken
    }
}
