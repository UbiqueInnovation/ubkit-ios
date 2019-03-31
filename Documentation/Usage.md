# UBFoundation Usage

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

Networking offers wrappers around the default iOS URLSession to make it safer and easier to use. Mainly you will be using the `HTTPDataTask` class, in combination with the `HTTPURLRequest` to achieve network requests and load data.

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

### Network Activity
It is important to show feedback to users when a network activity is running. There for the global methods available in `Networking` can help you add observers and adapt the UI accornigly. The callback will be fired each time the global network activity changes status (from idle to fetching or vis versa). Only the `HTTPDataTask` object created with the default session will be added automatically, otherwise you need to add them manually (more info in the `Networking` object)
```swift
Networking.addNetworkActivityStateObserver { (newState) in
    // Change UI accordingly
    UIApplication.shared.isNetworkActivityIndicatorVisible = (newState == .fetching)
}
```

## UIColor from HEX
If you need to instanciate a color from a HEX value or you need to output a color as a HEX string you can use.
```swift
let mainColor = UIColor(hexString: "#FF00FF")
print(mainColor?.hexString ?? "No color")
```
## Keyboard Layout Guide
The keyboard layout guide of a view will represent the area of that view that is obstructed by the keyboard. Making constraints to the top of the keyboard layout guide ensures that the content is always visible when the keyboard shows
```swift
// Make sure that the input field is always above of the keyboard. Otherwise mapped to the bottom of the parent view.
inputField.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true
```
## Cron Jobs
A `CronJob` is a class that invoces a function at a specific point in time. It can repeat or not. If the deadline is passed and the code could not be executed due to app halt or sleep, then the function is invoked as soon as possible on system resume.
> You should keep reference to the job object. If the job gets deallocated

```swift
let job = CronJob(fireAt: date) {
    // The cron job to be executed
}
```
