//
//  StackScrollView.swift
//
//
//  Created by Matthias Felix on 14.07.21.
//

import UIKit

/// Wraps a UIStackView inside a UIScrollView and provides utility methods for adding and removing subviews
public class StackScrollView: UIView {
    // MARK: - Subviews

    private let stackViewContainer = UIView()
    public let stackView = UIStackView()
    public let scrollView = UIScrollView()

    private var addedViewControllers: [UIView: UIViewController] = [:]

    // MARK: - Initialization

    public init(axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 0) {
        super.init(frame: .zero)

        switch axis {
        case .vertical:
            scrollView.alwaysBounceVertical = true
        case .horizontal:
            scrollView.alwaysBounceHorizontal = true
        @unknown default:
            fatalError()
        }

        // Add scrollView
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Add stackViewContainer and stackView
        scrollView.addSubview(stackViewContainer)

        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackViewContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackViewContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackViewContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackViewContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])

        switch axis {
        case .vertical:
            stackViewContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        case .horizontal:
            stackViewContainer.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        @unknown default:
            fatalError()
        }

        stackView.axis = axis
        stackView.spacing = spacing
        stackViewContainer.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: stackViewContainer.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: stackViewContainer.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: stackViewContainer.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: stackViewContainer.widthAnchor),
        ])
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    /// Adds a view to the stack view
    /// - Parameters:
    ///    - view: The view to be added
    ///    - size: If specified, a height or width constraint will be added to the added view
    ///    - index: If specified, the view will be inserted at the specified index. If nil, the view will be added to the end of the stack view
    ///    - inset: If specified, the view will be put into a wrapper view with the specified insets, and the wrapper view will be added to the stack view
    public func addArrangedView(_ view: UIView, size: CGFloat? = nil, index: Int? = nil, inset: UIEdgeInsets? = nil) {
        view.translatesAutoresizingMaskIntoConstraints = false
        if let s = size {
            switch stackView.axis {
            case .vertical:
                view.heightAnchor.constraint(equalToConstant: s).isActive = true
            case .horizontal:
                view.widthAnchor.constraint(equalToConstant: s).isActive = true
            @unknown default:
                fatalError()
            }
        }

        let subView: UIView
        if let inset = inset {
            subView = UIView()
            subView.addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: subView.topAnchor, constant: inset.top),
                view.bottomAnchor.constraint(equalTo: subView.bottomAnchor, constant: -inset.bottom),
                view.leadingAnchor.constraint(equalTo: subView.leadingAnchor, constant: inset.left),
                view.trailingAnchor.constraint(equalTo: subView.trailingAnchor, constant: -inset.right),
            ])
        } else {
            subView = view
        }

        if let i = index {
            stackView.insertArrangedSubview(subView, at: i)
        } else {
            stackView.addArrangedSubview(subView)
        }
    }

    /// Adds a view to the stack view and centers it either horizontally or vertically
    /// - Parameters:
    ///    - view: The view to be added
    ///    - inset: If specified, the view will be inset from the horizontal or vertical edges by this amount
    public func addArrangedViewCentered(_ view: UIView, inset: CGFloat = 0) {
        let wrapper = UIView()
        wrapper.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false

        switch stackView.axis {
        case .vertical:
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: wrapper.topAnchor),
                view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
                view.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: wrapper.leadingAnchor, constant: inset),
                view.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor, constant: -inset),
            ])
        case .horizontal:
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
                view.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
                view.topAnchor.constraint(greaterThanOrEqualTo: wrapper.topAnchor, constant: inset),
                view.bottomAnchor.constraint(lessThanOrEqualTo: wrapper.bottomAnchor, constant: -inset),
            ])
        @unknown default:
            fatalError()
        }

        addArrangedView(wrapper)
    }

    /// Adds the view of another view controller to the stack view, taking care of adding the view controller as a child as well
    /// - Parameters:
    ///    - viewController: The view controller whose view should be added to the stack view
    ///    - parent: The view controller will be added as child to this parent
    ///    - size: If specified, the view will have this height or width, depending on the stack view's orientation
    ///    - index: If specified, the view will be inserted to this index in the stack view instead of added at the end
    public func addArrangedViewController(_ viewController: UIViewController, parent: UIViewController, size: CGFloat? = nil, index: Int? = nil) {
        parent.addChild(viewController)
        addArrangedView(viewController.view, size: size, index: index)
        viewController.didMove(toParent: parent)

        self.addedViewControllers[viewController.view] = viewController
    }

    /// Adds a spacer view of the specified size to the stack view
    /// - Parameters:
    ///    - size: The height (vertical stack view) or width (horizontal stack view) of the spacer
    ///    - color: If specified, the view will get this color, if omitted, it will be transparent
    /// - Returns: The spacer view that was added to the stack view
    @discardableResult
    public func addSpacerView(_ size: CGFloat, color: UIColor? = nil) -> UIView {
        let extraSpacer = UIView()
        extraSpacer.backgroundColor = color
        addArrangedView(extraSpacer, size: size)
        return extraSpacer
    }

    /// Removes a view from the stack view
    /// - Parameters:
    ///    - view: The view to remove
    public func removeView(_ view: UIView) {
        if let vc = addedViewControllers[view] {
            vc.willMove(toParent: nil)
            view.removeFromSuperview()
            vc.removeFromParent()
            addedViewControllers.removeValue(forKey: view)
        } else {
            view.removeFromSuperview()
        }
    }

    /// Removes a viewController from the stack view
    /// - Parameters:
    ///    - viewController: The viewController to remove
    public func removeViewCotroller(_ viewController: UIViewController) {
        self.removeView(viewController.view)
    }

    /// Removes all views from the stack view
    public func removeAllViews() {
        stackView.arrangedSubviews.forEach { removeView($0) }
    }

    /// Scrolls a specific area of the content so that it is visible in the receiver.
    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        scrollView.scrollRectToVisible(rect, animated: animated)
    }

    /// Scrolls the scrollview all the way to the top
    public func scrollToTop(animated _: Bool) {
        var offset = CGPoint(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)

        if #available(iOS 11.0, *) {
            offset = CGPoint(x: -scrollView.adjustedContentInset.left, y: -scrollView.adjustedContentInset.top)
        }

        scrollView.setContentOffset(offset, animated: true)
    }
}
