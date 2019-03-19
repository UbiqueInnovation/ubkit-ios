fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### setup
```
fastlane setup
```
Setup the project.
### release
```
fastlane release
```
Deploy the framework.
### documentation
```
fastlane documentation
```
Opens the documentation. Option `generate:true` to generates it also.
### update_version
```
fastlane update_version
```
Update the version of the project.
### tests
```
fastlane tests
```
Run the unit tests. show_results:true to open the result page

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
