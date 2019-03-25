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
You can aslo find plenty of guides under the Documentation folder in the project.

## License

Copyright (c) 2019-present Ubique Innovation AG
