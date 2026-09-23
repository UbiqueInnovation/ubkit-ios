import MapKit
import SwiftUI

struct LocationOverrideMapView: View {
    @Binding var latitude: String
    @Binding var longitude: String
    @State private var liveCoordinate = CLLocationCoordinate2D(latitude: 46.8, longitude: 8.3)

    var body: some View {
        VStack(spacing: 0) {
            Text("Lat \(liveCoordinate.latitude, specifier: "%.3f")  ·  Lon \(liveCoordinate.longitude, specifier: "%.3f")")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .padding(.vertical, 12)
            ZStack {
                LocationOverrideMap(latitude: $latitude, longitude: $longitude, liveCoordinate: $liveCoordinate)
                Image(systemName: "mappin")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                    .shadow(radius: 2)
                    .frame(width: 48, height: 48, alignment: .bottom)
                    .offset(y: -24)
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("Pick location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let coordinate = LocationOverrideDevTools.coordinate(latitude: latitude, longitude: longitude) {
                liveCoordinate = coordinate
            } else {
                latitude = "46.8"
                longitude = "8.3"
            }
        }
    }
}

private struct LocationOverrideMap: UIViewRepresentable {
    @Binding var latitude: String
    @Binding var longitude: String
    @Binding var liveCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let selected = LocationOverrideDevTools.coordinate(latitude: latitude, longitude: longitude)
        let center = selected ?? CLLocationCoordinate2D(latitude: 46.8, longitude: 8.3)
        mapView.setRegion(
            MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 5.2)),
            animated: false
        )
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_: MKMapView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocationOverrideMap

        init(_ parent: LocationOverrideMap) {
            self.parent = parent
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.liveCoordinate = mapView.centerCoordinate
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
            let coordinate = mapView.centerCoordinate
            parent.liveCoordinate = coordinate
            parent.latitude = String(coordinate.latitude)
            parent.longitude = String(coordinate.longitude)
        }
    }
}
