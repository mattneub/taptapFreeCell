import UIKit

protocol GameViewInterfaceConstructorType {
    func constructInterface(in view: UIView) -> [[CardView]]
}

/// Helper object that builds the interface by laying out card views.
struct GameViewInterfaceConstructor : GameViewInterfaceConstructorType {
    func constructInterface(in view: UIView) -> [[CardView]] {
        let margin: CGFloat = max(16, (view.bounds.width - MAXWIDTH) / 2)
        // foundations
        let foundation1 = CardView(location: Location(category: .foundation, index: 3)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        foundation1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).activate()
        foundation1.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin).activate()
        let foundation2 = CardView(location: Location(category: .foundation, index: 2)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        foundation2.topAnchor.constraint(equalTo: foundation1.topAnchor).activate()
        foundation2.trailingAnchor.constraint(equalTo: foundation1.leadingAnchor, constant: -10).activate()
        let foundation3 = CardView(location: Location(category: .foundation, index: 1)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        foundation3.topAnchor.constraint(equalTo: foundation1.topAnchor).activate()
        foundation3.trailingAnchor.constraint(equalTo: foundation2.leadingAnchor, constant: -10).activate()
        let foundation4 = CardView(location: Location(category: .foundation, index: 0)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        foundation4.topAnchor.constraint(equalTo: foundation1.topAnchor).activate()
        foundation4.trailingAnchor.constraint(equalTo: foundation3.leadingAnchor, constant: -10).activate()
        // freecells
        let freecell1 = CardView(location: Location(category: .freeCell, index: 0)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        freecell1.topAnchor.constraint(equalTo: foundation1.bottomAnchor, constant: 8).activate()
        freecell1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin).activate()
        let freecell2 = CardView(location: Location(category: .freeCell, index: 1)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        freecell2.topAnchor.constraint(equalTo: freecell1.topAnchor).activate()
        freecell2.leadingAnchor.constraint(equalTo: freecell1.trailingAnchor, constant: 10).activate()
        let freecell3 = CardView(location: Location(category: .freeCell, index: 2)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        freecell3.topAnchor.constraint(equalTo: freecell1.topAnchor).activate()
        freecell3.leadingAnchor.constraint(equalTo: freecell2.trailingAnchor, constant: 10).activate()
        let freecell4 = CardView(location: Location(category: .freeCell, index: 3)).applying {
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.activate()
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.activate()
        }
        freecell4.topAnchor.constraint(equalTo: freecell1.topAnchor).activate()
        freecell4.leadingAnchor.constraint(equalTo: freecell3.trailingAnchor, constant: 10).activate()
        let stackView = UIStackView().applying {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.alignment = .top
            $0.distribution = .equalSpacing
            view.addSubview($0)
        }
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: margin).activate()
        stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -margin).activate()
        stackView.topAnchor.constraint(equalTo: freecell1.bottomAnchor, constant: 8).activate()
        for index in 0..<8 {
            let column = CardView(location: Location(category: .column, index: index)).applying {
                view.addSubview($0)
                $0.widthConstraint.constant = CardView.baseSize.width
                $0.widthConstraint.activate()
                $0.heightConstraint.constant = CardView.baseSize.height
                $0.heightConstraint.activate()
            }
            stackView.addArrangedSubview(column)
        }
        return [
            [
                foundation4, foundation3, foundation2, foundation1
            ],
            [
                freecell1, freecell2, freecell3, freecell4
            ],
            stackView.arrangedSubviews.compactMap { $0 as? CardView }
        ]
    }
}
