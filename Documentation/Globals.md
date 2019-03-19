# Framework Globals

This is a document showing the different options for controlling the framework global settings from within your code at runtime.

## Logging
### Log Level
You can change the log level of the framework at anytime to 3 different values:
- `none`: no logging will be produced from the Framework
- `default`: will only generate logging of messages only
- `verbose`: will log on top of the messages: the thread, file, function and line of code.

To change the log level you can simply use the function:  
`UBFoundation.Logging.setGlobalLogLevel(_ newLogLevel: Logger.LogLevel)` 
