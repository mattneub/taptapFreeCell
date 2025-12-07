import Foundation

struct HelpState: Equatable {
    private let nextPrevs = """
    rules
    rules2
    rules3
    rules4
    rules5
    supermoves
    strategy
    taptap
    taptap2
    taptap3
    taptap4
    preferences
    preferences2
    preferences3
    preferences4
    preferences5
    statistics
    otherfeatures
    propack
    """

    var helpType: HelpType

    var nextPrevsArray: [String] {
        nextPrevs.split(separator: "\n").map(String.init)
    }

    var initialIndex: Int {
        switch helpType {
        case .help: 7
        case .rules: 0
        }
    }

    var undoStack = [String]()

    enum HelpType {
        case help
        case rules
    }
}
