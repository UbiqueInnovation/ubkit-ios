//
//  UICollectionView+Helpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

extension UICollectionReusableView: ReusableView {}

// MARK: - Registering and Reusing Cells
extension UICollectionView
{
    /// Register a collection view cell for reuse.
    ///
    /// - Parameter cellType: The class of the collection view cell to register.
    func register<T: UICollectionViewCell>(_ cellType: T.Type) {
        self.register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    /// Dequeue a reusable colection view cell for displaying at a given index path.
    ///
    /// - Parameter indexPath: The index path where the cell will be placed.
    /// - Returns: A dequeued reusable cell.
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}

// MARK: - Registering and Reusing Supplementary Views
extension UICollectionView
{
    func register<T: UICollectionReusableView>(_ viewType: T.Type, forSupplementaryViewOfKind elementKind: String) {
        self.register(T.self, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> T {
        guard let view = self.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view with identifier: \(T.reuseIdentifier)")
        }
        return view
    }
}


// MARK: - Registering and Reusing Decoration Views

extension UICollectionViewLayout
{
    func register<T: UICollectionReusableView>(_ viewType: T.Type) {
        self.register(T.self, forDecorationViewOfKind: T.reuseIdentifier)
    }
}

extension UICollectionViewLayoutAttributes
{
    convenience init<T: UICollectionReusableView>(forDecorationViewOfType viewType: T.Type, with indexPath: IndexPath) {
        self.init(forDecorationViewOfKind: T.reuseIdentifier, with: indexPath)
    }
}
