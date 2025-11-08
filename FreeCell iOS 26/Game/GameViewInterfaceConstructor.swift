import UIKit

protocol GameViewInterfaceConstructorType {
    func constructInterface(in view: UIView) -> [[CardView]]
}

/// Helper object that builds the interface by laying out card views.
struct GameViewInterfaceConstructor : GameViewInterfaceConstructorType {
    func constructInterface(in view: UIView) -> [[CardView]] {
        // foundations
        var suits = Array(Suit.foundationOrder.reversed())
        let foundation1 = CardView(category: .foundation(suits.removeFirst())).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        foundation1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        foundation1.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        let foundation2 = CardView(category: .foundation(suits.removeFirst())).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        foundation2.topAnchor.constraint(equalTo: foundation1.topAnchor).isActive = true
        foundation2.trailingAnchor.constraint(equalTo: foundation1.leadingAnchor, constant: -10).isActive = true
        let foundation3 = CardView(category: .foundation(suits.removeFirst())).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        foundation3.topAnchor.constraint(equalTo: foundation1.topAnchor).isActive = true
        foundation3.trailingAnchor.constraint(equalTo: foundation2.leadingAnchor, constant: -10).isActive = true
        let foundation4 = CardView(category: .foundation(suits.removeFirst())).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        foundation4.topAnchor.constraint(equalTo: foundation1.topAnchor).isActive = true
        foundation4.trailingAnchor.constraint(equalTo: foundation3.leadingAnchor, constant: -10).isActive = true
        // freecells
        let freecell1 = CardView(category: .freeCell).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        freecell1.topAnchor.constraint(equalTo: foundation1.bottomAnchor, constant: 8).isActive = true
        freecell1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        let freecell2 = CardView(category: .freeCell).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        freecell2.topAnchor.constraint(equalTo: freecell1.topAnchor).isActive = true
        freecell2.leadingAnchor.constraint(equalTo: freecell1.trailingAnchor, constant: 10).isActive = true
        let freecell3 = CardView(category: .freeCell).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        freecell3.topAnchor.constraint(equalTo: freecell1.topAnchor).isActive = true
        freecell3.leadingAnchor.constraint(equalTo: freecell2.trailingAnchor, constant: 10).isActive = true
        let freecell4 = CardView(category: .freeCell).applying {
            $0.redraw()
            view.addSubview($0)
            $0.widthConstraint.constant = CardView.baseSize.width
            $0.widthConstraint.isActive = true
            $0.heightConstraint.constant = CardView.baseSize.height
            $0.heightConstraint.isActive = true
        }
        freecell4.topAnchor.constraint(equalTo: freecell1.topAnchor).isActive = true
        freecell4.leadingAnchor.constraint(equalTo: freecell3.trailingAnchor, constant: 10).isActive = true
        let stackView = UIStackView().applying {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.alignment = .top
            $0.distribution = .equalSpacing
            view.addSubview($0)
        }
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        stackView.topAnchor.constraint(equalTo: freecell1.bottomAnchor, constant: 8).isActive = true
        for _ in 1...8 {
            let column = CardView(category: .column).applying {
                $0.redraw()
                view.addSubview($0)
                $0.widthConstraint.constant = CardView.baseSize.width
                $0.widthConstraint.isActive = true
                $0.heightConstraint.constant = CardView.baseSize.height
                $0.heightConstraint.isActive = true
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
