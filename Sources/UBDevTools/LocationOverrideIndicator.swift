import UIKit

@MainActor
final class LocationOverrideIndicator: UIView {
    private static var observers: [NSObjectProtocol] = []
    private static let lightGreen = UIColor(red: 0.15, green: 0.63, blue: 0.31, alpha: 1)
    private static let darkGreen = UIColor(red: 0.04, green: 0.38, blue: 0.18, alpha: 1)

    static func setup() {
        guard observers.isEmpty else { return }
        observers = [UIWindow.didBecomeKeyNotification, UserDefaults.didChangeNotification]
            .map { name in
                NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                    MainActor.assumeIsolated { refresh() }
                }
            }
        refresh()
    }

    static func refresh() {
        let active = UBDevTools.isActivated && LocationOverrideDevTools.location != nil
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                let indicator = window.subviews.first { $0 is LocationOverrideIndicator } as? LocationOverrideIndicator
                if active && window.isKeyWindow && window.windowLevel == .normal {
                    if let indicator {
                        window.bringSubviewToFront(indicator)
                    } else {
                        let indicator = LocationOverrideIndicator(frame: .zero)
                        window.addSubview(indicator)
                        NSLayoutConstraint.activate([
                            indicator.widthAnchor.constraint(equalToConstant: 34),
                            indicator.heightAnchor.constraint(equalToConstant: 34),
                            indicator.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 6),
                            indicator.centerXAnchor.constraint(equalTo: window.safeAreaLayoutGuide.centerXAnchor),
                        ])
                        indicator.startColorAnimation()
                    }
                } else {
                    indicator?.removeFromSuperview()
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityLabel = "Location override active"
        backgroundColor = Self.lightGreen
        layer.cornerRadius = 17
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)

        let pin = UIImageView(image: UIImage(systemName: "mappin"))
        pin.tintColor = .white
        pin.contentMode = .scaleAspectFit
        pin.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 16),
            pin.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startColorAnimation() {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = Self.lightGreen.cgColor
        animation.toValue = Self.darkGreen.cgColor
        animation.duration = 1.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "colorAnimation")
    }
}
