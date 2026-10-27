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
                        let frame = contentFrame(in: proxy)

                        VStack(alignment: .center) {
                            Spacer()
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
                            Spacer()
                        }
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                    }
                    .background(
                        style.backdropColor
                            .ignoresSafeArea()
                            .onTapGesture {
                                if style.tapOutsideToDismiss {
                                    isPresented = false
                                }
                            }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.vertical)
                }
            }
            .transition(.opacity)
            .animation(.default, value: isPresented)
        }

        private func contentFrame(in proxy: GeometryProxy) -> CGRect {
            var division: CGRect?
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                division = proxy.reservedRegions(kind: .division, layoutDirectionBehavior: .fixed).first?.frame
            }
            return Self.contentFrame(size: proxy.size, division: division)
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

#endif
