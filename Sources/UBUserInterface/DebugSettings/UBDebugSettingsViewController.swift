//
//  UBDebugSettingsViewController.swift
//  
//
//  Created by Stefan Mitterrutzner on 06.05.22.
//

import UIKit

open class UBDebugSettingsViewController: UIViewController {
    private let stackScrollView = StackScrollView(axis: .vertical, spacing: 12.0)

    public var elements: [UBBaseSetting] = [] {
        didSet {
            updateElements()
        }
    }

    open override func viewDidLoad() {
        setupLayout()
        title = "Debug Settings"
    }

    func setupLayout(){
        self.view.addSubview(stackScrollView)

        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .secondarySystemBackground
        } else {
            self.view.backgroundColor = .lightGray
        }

        stackScrollView.stackView.isLayoutMarginsRelativeArrangement = true
        stackScrollView.stackView.layoutMargins = .init(top: 0, left: 12.0, bottom: 0.0, right: 12.0)

        stackScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            stackScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func updateElements() {
        stackScrollView.removeAllViews()
        elements.forEach{ stackScrollView.addArrangedView($0.getView()) }
    }
}

open class UBBaseSetting {
    func getView() -> UIView {
        fatalError("implement in subclass")
    }
}

open class UBSettingsElement<T: Equatable>: UBBaseSetting {
    var value: T {
        didSet {
            valueDidCange(oldValue: oldValue)
        }
    }

    var valueDidChangeCallback:  (( _ newValue: T)->())?

    init(value: T) {
        self.value = value
    }

    func valueDidCange(oldValue: T) {
        guard oldValue != value else { return }
        valueDidChangeCallback?(value)
    }
}

open class UBSettingsLabelRow: UIView {
    let label = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        self.label.text = text
        setupLayout()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLayout() {
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }

        layer.cornerRadius = 5.0
        layer.masksToBounds = true

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8.0)
        ])
    }
}

open class UBSettingsSelectionView: UBSettingsLabelRow {

    private let switchControl  = UISwitch()

    private let didChangeValue: ((_ value: Bool ) -> ())

    public var value: Bool {
        didSet {
            switchControl.isOn = value
        }
    }

    public init(text: String, value: Bool, callback: @escaping ((_ value: Bool ) -> ())) {
        self.didChangeValue = callback
        switchControl.isOn = value
        self.value = value

        super.init(text: text)

        switchControl.addTarget(self, action: #selector(onSwitchValueChanged), for: .valueChanged)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func onSwitchValueChanged(_ switchControl: UISwitch) {
        value = switchControl.isOn
        didChangeValue(value)
    }

    override func setupLayout() {
        super.setupLayout()

        addSubview(switchControl)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            switchControl.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
            switchControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),
            switchControl.leadingAnchor.constraint(equalTo: self.label.trailingAnchor, constant: 8.0),
            switchControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0)
        ])
    }
}

public class UBBooleanSettingsElement: UBSettingsElement<Bool> {

    private var view: UBSettingsSelectionView!

    public init(text: String, value: Bool, callback: @escaping ((_ value: Bool ) -> ())) {
        super.init(value: value)
        view = .init(text: text, value: value, callback: {[weak self] value in
            guard let self = self else { return }
            self.value = value
        })
        self.valueDidChangeCallback = callback
    }

    public init(text: String, userDefaultsKey: String, userDefaults: UserDefaults = .standard, callback: ((_ value: Bool ) -> ())? = nil) {
        let value = userDefaults.bool(forKey: userDefaultsKey)
        super.init(value: value)
        self.valueDidChangeCallback = callback
        view = .init(text: text, value: value, callback: {[weak self] value in
            guard let self = self else { return }
            self.value = value
            userDefaults.set(value, forKey: userDefaultsKey)
        })
    }

    override func getView() -> UIView {
        view
    }
}


open class UBSettingsGroup: UBBaseSetting {
    private let elements: [UBBaseSetting]
    private let title: String
    public init(title: String, _ elements: [UBBaseSetting]){
        self.title = title
        self.elements = elements
    }
    override func getView() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.text = title

        let titleWrapper = UIView()
        titleWrapper.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleWrapper.topAnchor, constant: 8.0),
            titleLabel.bottomAnchor.constraint(equalTo: titleWrapper.bottomAnchor, constant: -8.0),
            titleLabel.leadingAnchor.constraint(equalTo: titleWrapper.leadingAnchor, constant: 8.0),
            titleLabel.trailingAnchor.constraint(equalTo: titleWrapper.trailingAnchor, constant: -8.0)
        ])

        var views: [UIView] = [titleWrapper]
        views.append(contentsOf: elements.map{ $0.getView() })

        let stackView = UIStackView(arrangedSubviews: views )

        if #available(iOS 13.0, *) {
            stackView.backgroundColor = .systemBackground
        } else {
            stackView.backgroundColor = .white
        }

        stackView.layer.cornerRadius = 5.0
        stackView.layer.masksToBounds = true

        stackView.axis = .vertical
        return stackView
    }
}
