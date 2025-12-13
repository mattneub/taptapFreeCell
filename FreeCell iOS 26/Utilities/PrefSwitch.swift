import UIKit

/// UISwitch that keeps a copy of the PrefKey whose value it represents.
final class PrefSwitch: UISwitch {
    var prefKey: PrefKey?
}
