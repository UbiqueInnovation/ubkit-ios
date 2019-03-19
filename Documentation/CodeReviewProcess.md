# Code Review Process

## Documentation and Comments
- New functions or types with a ACL of `public` or `open` should be documented in a way that ensures proper understanding from the caller. Add in notes, description as needed to remove any ambiguity.
- `internal` or `private` ACL types must have a simple documentation, unless the naming is very obvious.
- Functions that do not require documentation should be annotated with `\\\ :nodoc:` to signal that the lack of documentation is intended.
- If the body of a function is complicated, small one line comments are required.
- If a hack is done or a non-standard coding way is needed. A comment explaining the need and pointing the problem should be present.
- Run `fastlane documentation` and check for missing documentation.
- Update any outdated documentation when fuction or type changes.

## Unit tests
- All new code needs to have unit tests.
- Check code coverage
- Make sure the target test passes.

## Logging
- Logging should be by module. Each module should have a logger.
- Creating a logger for internal use is made via the Factory call in the `Logging` helper.
- Logs are correctly attributed the access level. All sensitive data should be marked as `private`.
- Logs types are correctly used. `error` and `info` can be seen by the user. `debug` is only intended for development.
- Make sure that logs are inserted regularly to provide insights on the inner working of the framework.

## Access control
Verify that all methods have a correct level of access control. Only functions and variables for the framework users should be marked as `public` or `open`.

## Localization and Bundles
- No static strings should be returned without beign localized.
- Usage of the framework localization helper.
- Usage of formatters for numbers, dates and names.
- Usage of the localized bundle for fetching resources.
- Verify that the `main` bundle is only used for resources that should be located on the app side.

## Thread safety
- Verify if a call can be made from different threads.
- Verify that no starvation can happen.
- If a class or method is thread safe, then the documentation should also metion it.
