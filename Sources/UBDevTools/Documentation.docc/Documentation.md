# UBDevTools

UBDevTools adds a hidden debug view to any app.


* Clear and modify user defaults
* Clear and modify keychain
* Delete URLCache
* Show view debug borders
* Show finger tips
* Show localization keys
* Set backend URLs
* Enable raster tile debug overlay
* Export documentsDirectory

## Usage

Using UBDevTools is as simple as adding a few lines to your Xcode project. 

For **UIKit**:

```swift
#if DEBUG
    import UBDevTools
#endif

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       #if DEBUG
           UBDevTools.setup()
            // Configure your backend URLs
           UBDevTools.setupBaseUrls(baseUrls: [
               BaseUrl(title: "WS Base URL", url: "https://www.my-url.ch"),
               BaseUrl(title: "IDP Base URL", url: "https://www.my-idp.ch"),
           ])
           UBDevTools.setupSharedUserDefaults(UserPreferences.sharedDefaults)
       #endif
}

```

For **SwiftUI**:

```swift
#if DEBUG
    import UBDevTools
#endif


@main
struct MyApp: App {
    init() {
        #if DEBUG
            UBDevTools.setup()
            UBDevTools.setupBaseUrls(baseUrls: [
                BaseUrl(title: "WS Base URL", url: "https://www.my-url.ch"),
                BaseUrl(title: "IDP Base URL", url: "https://www.my-idp.ch"),
            ])
        #endif
    }

    var body: some Scene {
        // ...
    }
}
```

## Contributing to UBKit

Please see the [contributing guide](/Contribution Guide.md) for more information.
