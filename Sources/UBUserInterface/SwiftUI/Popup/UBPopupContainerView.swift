//
//  UBPopupContainerView.swift
//
//
//  Created by Matthias Felix on 05.10.22.
//

#if arch(arm64) || arch(x86_64)

    import SwiftUI

    struct UBPopupContainerView: View {
        @Binding var isPresented: Bool
        let style: UBPopupStyle
        let content: () -> AnyView

        var body: some View {
            ZStack {
                if isPresented {
                    GeometryReader { proxy in
                        if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                            let division = proxy.reservedRegions(kind: .division).first?.frame
                            let pane = Self.contentFrame(size: proxy.size, division: division)

                            ScrollView([.horizontal, .vertical]) {
                                PopupPaneLayout(size: pane.size, isDivided: pane.size != proxy.size) {
                                    popup
                                }
                                .background {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture { dismissFromBackdrop() }
                                }
                            }
                            .scrollBounceBehavior(.basedOnSize, axes: [.horizontal, .vertical])
                            .frame(width: pane.width, height: pane.height)
                            .clipped()
                            .position(x: pane.midX, y: pane.midY)
                        } else {
                            VStack {
                                Spacer()
                                popup
                                Spacer()
                            }
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        }
                    }
                    .background(
                        style.backdropColor
                            .ignoresSafeArea()
                            .onTapGesture { dismissFromBackdrop() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.vertical)
                }
            }
            .transition(.opacity)
            .animation(.default, value: isPresented)
        }

        @ViewBuilder
        private var popup: some View {
            if style.extendsToEdges {
                HStack {
                    Spacer()
                    content()
                        .padding(style.insets)
                    Spacer()
                }
                .background(style.backgroundColor)
                .cornerRadius(style.cornerRadius)
                .padding(style.horizontalPadding)
            } else {
                HStack {
                    Spacer()
                    content()
                        .padding(style.insets)
                        .background(style.backgroundColor)
                        .cornerRadius(style.cornerRadius)
                        .padding(style.horizontalPadding)
                    Spacer()
                }
            }
        }

        private func dismissFromBackdrop() {
            if style.tapOutsideToDismiss {
                isPresented = false
            }
        }

        static func contentFrame(size: CGSize, division: CGRect?) -> CGRect {
            let bounds = CGRect(origin: .zero, size: size)
            guard let division, bounds.intersects(division) else { return bounds }

            let intersection = bounds.intersection(division)
            if division.height > division.width {
                let left = CGRect(x: 0, y: 0, width: intersection.minX, height: size.height)
                let right = CGRect(x: intersection.maxX, y: 0, width: size.width - intersection.maxX, height: size.height)
                return left.width >= right.width ? left : right
            } else {
                let top = CGRect(x: 0, y: 0, width: size.width, height: intersection.minY)
                let bottom = CGRect(x: 0, y: intersection.maxY, width: size.width, height: size.height - intersection.maxY)
                return top.height >= bottom.height ? top : bottom
            }
        }
    }

    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    private struct PopupPaneLayout: Layout {
        let size: CGSize
        let isDivided: Bool

        private var popupProposal: ProposedViewSize {
            ProposedViewSize(width: size.width, height: isDivided ? nil : size.height)
        }

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            guard isDivided else { return size }
            let popupSize = subviews[0].sizeThatFits(popupProposal)
            return CGSize(width: max(size.width, popupSize.width), height: max(size.height, popupSize.height))
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: popupProposal)
        }
    }

#endif
