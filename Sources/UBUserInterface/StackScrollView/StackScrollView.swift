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

    private var addedViewControllers : [UIView : UIViewController] = [:]

    // MARK: - Initialization

    public init(axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 0) {
        super.init(frame: .zero)

        switch axis {
        case .vertical:
            scrollView.alwaysBounceVertical = true
            scrollView.showsVerticalScrollIndicator = false
        case .horizontal:
            scrollView.alwaysBounceHorizontal = true
            scrollView.showsHorizontalScrollIndicator = false
        @unknown default:
            fatalError()
        }

        // Add scrollView
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        // Add stackViewContainer and stackView
        scrollView.addSubview(stackViewContainer)

        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        stackViewContainer.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackViewContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackViewContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackViewContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true

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

        stackView.ub_setContentPriorityRequired()
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.topAnchor.constraint(equalTo: stackViewContainer.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: stackViewContainer.bottomAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: stackViewContainer.centerXAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: stackViewContainer.widthAnchor).isActive = true
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
        var view = view

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

        if let inset = inset {
            let wrapper = UIView()
            wrapper.addSubview(view)
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: inset.top).isActive = true
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -inset.bottom).isActive = true
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: inset.left).isActive = true
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -inset.right).isActive = true
            view = wrapper
        }

        if let i = index {
            stackView.insertArrangedSubview(view, at: i)
        } else {
            stackView.addArrangedSubview(view)
        }
    }

    /// Adds a view to the stack view and centers it either horizontally or vertically
    /// - Parameters:
    ///    - view: The view to be added
    ///    - inset: If specified, the view will be inset from the horizontal or vertical edges by this amount
    public func addArrangedViewCentered(_ view: UIView, inset: CGFloat = 0) {
        let v = UIView()
        v.addSubview(view)
        v.translatesAutoresizingMaskIntoConstraints = false

        view.translatesAutoresizingMaskIntoConstraints = false

        switch stackView.axis {
        case .vertical:
            view.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
            view.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
            view.leadingAnchor.constraint(greaterThanOrEqualTo: v.leadingAnchor, constant: inset).isActive = true
            view.trailingAnchor.constraint(lessThanOrEqualTo: v.trailingAnchor, constant: -inset).isActive = true
        case .horizontal:
            view.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: v.trailingAnchor).isActive = true
            view.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
            view.topAnchor.constraint(greaterThanOrEqualTo: v.topAnchor, constant: inset).isActive = true
            view.bottomAnchor.constraint(lessThanOrEqualTo: v.bottomAnchor, constant: -inset).isActive = true
        @unknown default:
            fatalError()
        }

        addArrangedView(v)
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
    public func scrollToTop(animated: Bool) {
        var offset = CGPoint(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)

        if #available(iOS 11.0, *) {
            offset = CGPoint(x: -scrollView.adjustedContentInset.left, y: -scrollView.adjustedContentInset.top)
        }

        scrollView.setContentOffset(offset, animated: true)
    }
}
