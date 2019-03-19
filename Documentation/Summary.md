# UBFoundation modules

In this document you can find a list of modules and functionalities.

## Localization
The localization module is a wrapper around Appel's Bundle system and Local. It gives the caller control over the language and let it be specified at runtime.
You can start by checking the `Localization` class. Many formatters support this localization object in their initializer method.

## Logging
Logging is a wrapper module around Appel's unifide log API. It provides on top of the normal logging a set of useful control, like the log level and privacy.
The logging module is thread safe. To control the general logging of the framework pleare refer to the Globals guide.
> - `Logger`
> - `LoggerGroup`
