# UBFoundation
The UBFoundation framework provides a set of useful tools and helpers to make building apps faster and safer.

## Requirments
- iOS 11.0+ / Mac OS X 10.12+ / tvOS 12.0+ / watchOS 5.0+
- Xcode 10.0+
- Swift 4.2+

## Installation
### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](https://brew.sh) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate UBFoundation into your Xcode project using Carthage, specify it in your Cartfile:

```bash
git "git@bitbucket.org:ubique-innovation/ubfoundation-swift.git" "master"
```

Run `carthage update` to build the framework and drag the built UBFoundation.framework into your Xcode project.

### Manually
If you prefer not to use __Carthage__ as a dependency managers, you can integrate SnapKit into your project manually by checking out the source code and draging the project into your xCode project.

## Contribution
If you want to contribute to the framework, please check the contribution guide.

## Documentation
The framework is fully documented and easy to navigate on your own. You can consult the [online documentation](https://ubique.ch/ubFoundation/documentation). Or build it yourself by checking out the project and running the fastlane command `fastlane documentation`.

# Usage
## Localization
The localization module is a wrapper around Appel's Bundle system and Local. It gives the caller control over the language and let it be specified at runtime. `UBFoundation` comes with a `Localization` object. Most formatters also accept a `Localization` object as initialization argument.

- You can localize your strings by using the extension property `localized` directly on a key.

```swift
headerLabel.text = "balance_header_label".localized
```
_NB: To react to language changes you can observe one of the two `LocalizationNotification` notifications name on the default notification center._

- You can access the current `Localization` object by calling `UBFoundation.AppLocalization` 

```swift
// Creating a date picker with the correct locale

let datePicker = UIDatePicker(frame: .zero)
datePicker.locale = UBFoundation.AppLocalization.locale

// Fetching a file from the localized bundle 

let aboutHTMLFilePath = AppLocalization.localizedBundle?.path(forResource: "about", ofType: "html")
self.webview.load(aboutHTMLFilePath)
```

- To get all the available languages that app offers:

```swift
let allLanguages = Localization.availableLanguages()
print(allLanguages.map({ $0.displayNameInNativeLanguage }))
```

- To change the language:

```swift
try UBFoundation.setLanguage(languageCode: "en", regionCode: "CH")
```

## Logging
Logging is a wrapper module around Appel's unifide log API. It provides on top of the normal logging a set of useful control, like the log level and privacy.
The logging module is thread safe.

> We recommend that you creat a logger and have it accessible from all the app to make logging easier.
> You can delare many loggers with different categories to refine more the logs. But most apps will be fine with one.
> The logs can be seen in the xCode console if you are debugging the app, otherwise they will show up in the Console app.
> A nice place to store all you loggers is in a separate file, where you can declare static let property in the global scope.

```swift
// File: Logging.swift

let logger: Logger? = {
return try? Logger(category: "MyApp")
}()

```

- To create a logger and start logging you can

```swift
do {
let logger = try Logger(category: "Database")
logger.setLogLevel(.default)
// You can save a reference for the logger for further use
try database.open()
logger.debug("Connection to DB successfully open", accessLevel: .public)
try database.save(age: person.age, person: person)
logger.info("Saved age \(person.age) to contact \(person.name)", accessLevel: .private)
database.close()
logger.debug("Connection to DB closed", accessLevel: .public)
} catch {
logger.error("An error occurred while accessing the database \(error.localizedDescription)", accessLevel: .public)
}
```


- Setting the framework log Level
In case you want to change the log level of the framewotk you can do so by calling

```swift
// Turn off all framework logging
UBFoundation.Logging.setGlobalLogLevel(.none)
```

## Networking

Networking offers wrappers around the default iOS URLSession to make it eafer and easier to use.

### Loading a resource encoded in JSON
The Networking module offers a variaty of `HTTPDataDecoder` for decoding JSON or String but you can also create you own. Otherwise you can access the Data directly.
```swift
// Create a Data Task
let url = URL(string: "http://example.com/books")!
let request = HTTPURLRequest(url: url)
let task = HTTPDataTask(request: request)
task.addCompletionHandler(decoder: HTTPJSONDecoder<Books>()) { (result, _) in
switch result{
case .success(let books):
// Make something useful with the data
break
case .failure(let error):
// Show the error for the user
break
}
}
```

### Tracking progress
On some lengthy tasks showing the progress to the user is a good idea.
```swift
task.addProgressObserver { (_, progress) in
progressBar.progress = progress
}
```
### Monitoring state
You can monitor the state of the task and adapt the UI accordingly
```swift
task.addStateTransitionObserver { (_, new) in
switch new {
case .waitingExecution, .fetching:
activityIndicator.startAnimating()
default:
activityIndicator.stopAnimating()
}
}
```

### Validation
You can add validators to be executed after the response is received and check if we proceed to decode the data. Errors thrown will be available in the completion handler block.
```swift
task.addResponseValidator(HTTPResponseStatusValidator(.ok))
```

## License

Copyright (c) 2019-present Ubique Innovation AG
