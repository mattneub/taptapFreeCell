// http://prabhu.xyz/2017/05/08/particle-effects-in-swift-using-caemitterlayer.html

import UIKit

enum Colors {
    static let red = UIColor(red: 1.0, green: 0.0, blue: 77.0/255.0, alpha: 1.0)
    static let blue = UIColor.blue
    static let green = UIColor(red: 35.0/255.0 , green: 233/255, blue: 173/255.0, alpha: 1.0)
    static let yellow = UIColor(red: 1, green: 209/255, blue: 77.0/255.0, alpha: 1.0)
}

enum Images {
    static let box = UIImage(named: "Box", in: Bundle(for: ConfettiDropper.self), compatibleWith: nil)!
    static let triangle = UIImage(named: "Triangle", in: Bundle(for: ConfettiDropper.self), compatibleWith: nil)!
    static let circle = UIImage(named: "Circle", in: Bundle(for: ConfettiDropper.self), compatibleWith: nil)!
    static let swirl = UIImage(named: "Spiral", in: Bundle(for: ConfettiDropper.self), compatibleWith: nil)!
}

public final class ConfettiDropper {
    let displayScale: CGFloat

    public init(displayScale: CGFloat) {
        self.displayScale = displayScale
    }

    var emitter = CAEmitterLayer()

    var colors: [UIColor] = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow
    ]

    var images: [UIImage] = [
        Images.box,
        Images.triangle,
        Images.circle,
        Images.swirl
    ]

    var velocities: [Int] = [
        100,
        90,
        150,
        200
    ]

    public func addEmitter(to view: UIView) {
        emitter.emitterPosition = CGPoint(x: view.bounds.size.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.size.width, height: 2.0)
        emitter.emitterCells = generateEmitterCells()
        view.layer.addSublayer(emitter)
    }

    public func removeEmitter() {
        emitter.removeFromSuperlayer()
    }

    private func generateEmitterCells() -> [CAEmitterCell] {
        var cells: [CAEmitterCell] = [CAEmitterCell]()
        for index in 0..<16 {
            let cell = CAEmitterCell()

            cell.contentsScale = displayScale
            cell.birthRate = 4.0
            cell.lifetime = 14.0
            cell.lifetimeRange = 0
            cell.velocity = CGFloat(getRandomVelocity())
            cell.velocityRange = 0
            cell.emissionLongitude = CGFloat(Double.pi)
            cell.emissionRange = 0.5
            cell.spin = 3.5
            cell.spinRange = 0
            cell.color = getNextColor(i: index)
            cell.contents = getNextImage(i: index)
            cell.scaleRange = 0.25
            cell.scale = 0.3

            cells.append(cell)
        }

        return cells

    }

    private func getRandomVelocity() -> Int {
        return velocities[getRandomNumber()]
    }

    private func getRandomNumber() -> Int {
        return Int.random(in: 0..<4)
    }

    private func getNextColor(i: Int) -> CGColor {
        if i <= 4 {
            return colors[0].cgColor
        } else if i <= 8 {
            return colors[1].cgColor
        } else if i <= 12 {
            return colors[2].cgColor
        } else {
            return colors[3].cgColor
        }
    }

    private func getNextImage(i: Int) -> CGImage {
        return images[i % 4].cgImage!
    }
}


