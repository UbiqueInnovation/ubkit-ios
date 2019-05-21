# UBFoundation contribution guide

If you wish to contribute to the framework development you cando so by following this guide.

## Installation
Checkout the project, open  a Terminal and navigating to the project root folder, then run:
```bash
fastlane setup
```

> We use [Fastlane](https://fastlane.tools) to do all the automation.
> If you don't have fastlane installed and do not want to get insane trying 
> to solve all the issues that comes with it, you can follow this [guide](https://hackernoon.com/the-only-sane-way-to-setup-fastlane-on-a-mac-4a14cb8549c8):
> 1. Install `brew` from [Homebrew](http://brew.sh/)
> 2. Install `rbenv` (a ruby environment) by running `brew install rbenv ruby-build`
> 3. Add `if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi` to your Bash environment
> 4. Install __Ruby__ by running `rbenv install 2.4.1` then `rbenv global 2.4.1`
> 5. Install __Fastlane__ by running `gem install fastlane`
> Congratulation you keept your sanity without missing on anything.

## Creating and Submitting changes
For each change that needs to be introduces to the framework, start by creating a branch from `develop` and commit your changes there. Once ready, create a pull request to see your changes merged. You cannot push changes directly to `develop` or `master`.

## Naming conventions
- Each `public` or `open` class/struct/enum should be prefixed by __UB__. _Example: the class `CronJob` should be named `UBCronJob`.
- Each method or variable implemented as part of an extension to Swift standard type should be prefixed by **ub_**. _Example: the helper __var__ `localized` on `String` should be called `ub_localized`. 

## Project Organization
### Version Control
We use `git` as our version control and we host our code on a private repository in [Bitbucket Cloud](https://bitbucket.org/).

### Dependency Management
So far the need did not arise for 3rd party libraries or dependencies.
In case it is needed, we would advise to uses `carthage` as a dependency manager. [Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. We chose it because it is transparent and keeps our project clean.

### Documentation
Documentation is really important, so we created a script that will generate an Apple like documentation style called [Jazzy](https://github.com/realm/jazzy).

To generate the documentation locally run the `documentation` lane:
```bash
fastlane documentation
```

### Changelog
Documenting the significant changes between version is essential to keep a clear overview and an easier way to communicate withing the project.

Therefore we have a `CHANGELOG.md` file that contains all the changes between versions.
This document adhere to the format specified in [keepachangelog](https://keepachangelog.com/en/1.0.0/):
- Maintain a `## [Unreleased]` section at the top to add all new changes as we go
- Structure each release with subsections named: 
`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` and `Security`

To read the changelog you can run
```bash
fastlane open_changelog
```

### Versionning
Versioning is key to keep track of software releases and dependencies. Maintaining a comprehensive and coherent versioning standard will avoid any confusion later.

#### Versioning conventions
In summary a version consists of three positive non-null integers separated by a dot: `MAJOR.MINOR.PATCH` (_Ex: 2.5.3_).
Exception to this rule is major version `0` that is considered development phase and not stable (_Ex: 0.3.6_).

You can read more about the logic on [Sementic Versioning 2.0.0](https://semver.org).

In addition to the version a build number can be provided to separate different builds of the same version, specially during development. It should always follow the version and be placed between parenthisis. _Ex: 2.5.3 (1472)_

#### Versionning tools
##### Version bump
To avoid any human error, we use fastlane to update our version. 
Just run `fastlane update_version` and follow the instructions.
Or provide a `bump_type:[patch | minor | major]` to automatically increase the number.
For advanced usage an option `version` can be used to pass in directly the number.

### Testing
Unit tests are key in a good continuous integration environment. This is why we have plenty. 

You can either:
- hit `Cmd+U` in Xcode to run the unit tests
- use Fastlane by running `fastlane tests show_results:true`. Set `show_results` is `true` if you want to see the Summary HTML generated.

Check the results of the [latest local tests](../../fastlane/test_output/report.html)

### Code Sanity
We chose to have our code formatted and it's style checked programmatically to avoid any issues and conflicts. Ont top of making the code look better and consistant, it avoid possible bugs. We went for SwiftFormat as a formatter for the code and SwiftLint for the linting part. Both scripts run on every build correctling automatically all the layouts and code style.
1. [__SwiftFormat__](https://github.com/nicklockwood/SwiftFormat)
2. [__SwiftLint__](https://github.com/realm/SwiftLint): 

We enabled custom opt-in rules that can be found in the configuration file `.swiftlint.yml`

### Code quality
Please refer to the Code Reveiew documentation.

### Logging
To achieve logging we chose to go with the unified logging system offered by Apple through the OS.Log framework.

We wrote our own wrapper around the os_log C like function to make it Swift friendly.

We separate 3 log levels: __Info__, __Error__, __Debug__.

# Roadmap

## Networking

### Caching
### Cron scheduling

### Retrying Requests
- No network retry

### Error handling
- Offer base error handling
- Offer extention for error handling

### Reachability
- Network reachability
- Auto-retry on reachability

## UI
### Empty Table and Collection view
[https://github.com/dzenbot/DZNEmptyDataSet]
