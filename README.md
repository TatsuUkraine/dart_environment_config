# Environment Config Generator

[![pub package](https://img.shields.io/pub/v/environment_config.svg)](https://pub.dartlang.org/packages/environment_config)

Environment specific config generator.

Allows to specify env configuration during CI/CD build.

Primarily created to simplify Flutter build configuration.

## Features

- flexible configuration for Config class generation
- allows to specify pattern for field values
- allows to define required and optional keys for generation
- allows to export variables to `.env` file

## Note for Flutter developers

This package still will be maintained, but if you are using Flutter
version 1.17 and higher, consider using compile-time variables to
configure your environments instead of this package. More about
compile-time variables you can read
[here](https://medium.com/@tatsu.ukraine/flutter-1-17-no-more-flavors-no-more-ios-schemas-command-argument-that-solves-everything-8b145ed4285d)

## Migration from 1.x.x to 2.x.x

In `1.x.x` path for `.env` was generated against `lib/` folder. Starting
from `2.x.x` path for `.env` file is generated against your root app
folder.

So by default `.env` file will be generated alongside with
`pubspec.yaml` and other root files.

## Table of contents

- [Getting Started](#getting-started)
- [Configuration](#config)
  - [Command options](#command-options)
  - [Class configuration](#class-configuration)
    - [Class configuration examples](#config-examples)
  - [Field configuration](#field-configuration)
    - [Fields config examples](#fields-config-examples)
      - [Pattern example](#pattern-example)
      - [DotEnv example](#dotenv-example)
      - [Global environment variable example](#global-environment-variable-example)
  - [Extensions](#extensions)
    - [Basic Extension config usage](#basic-extension-config-usage)
    - [Development Extension example](#development-extension-example)
- [Integration with CI/CD](#integration-with-cicd)
- [Integration with other packages](#integration-with-other-packages)

## Getting Started

Install package as dependency. Or use global active

`dart pub global activate environment_config`

Create `environment_config.yaml` or update `package.yaml` file with following code

**Note** This is an example with ALL possible params

```yaml
environment_config:
  path: environment_config.dart # optional, result file path against `lib/` folder
  dotenv_path: .env # optional, result file path for .env file against project root folder
  class: EnvironmentConfig # optional, class name
  dev_extension: # optional, by default undefined, allows to specify command option to use extension
  
  fields: # set of fields for command
    some_key: # key name
      type: # optional, default to 'String'
      short_name: # optional, short name for key during command run
      const: # optional, default to TRUE
      pattern: # optional, specified pattern for key value, use __VALUE__ to insert entered value anywhere in the pattern
      default: # optional, default value for key, if not provided key will be required during command run
      dotenv: # optional, default to FALSE, if this field should be added to .env file
      config_field: # optional, default to TRUE, if this field should be added to Dart file
      env_var: # optional, global environment variable name
      static: # options, default to TRUE, if this field should be static, if FALSE, `const` will be be ignored
      
  imports: # optional, array of imports, to include in config file
    - package:some_package
      
  extensions: # set of extensions for default field list
    some_extension: # extension name
      some_key:
        const: # optional, overrides `const` value for the field
        pattern: # optional, overrides `pattern` value for the field
        default: # optional, overrides `default` value for the field
        env_var: # optional, overrides `env_var` value for the field
        
    imports: # optional, adds set of imports to main configulration
      - package:some_other_package
      
```

Run `pub get` to install dependencies. (if you installed it as deps in you project)

After config is specified in YAML file run following command

```
pub run environment_config:generate --some_key=some_value
```
Or for flutter project

```
flutter pub run environment_config:generate --some_key=some_value
```

Or just next command if you installed package globally

```
environment-config-generate --some_key=some_value
```

This command with generate file, that was specified in `path` key with
class, fields and name specified in yaml config.

Import this file into your application and use it.

**Note:** It's recommended to add generated config files to `.gitignore`

## Why this package is needed?

This package allows to integrate config generation based on environment
in an easy way.

Unlike most env specific configurations this package can be added to
CI/CD build process to generate config file with values, that specific to
particular env, without need to specify your Prod credentials
anywhere except your build process.

Also reading this values doesn't require async process, that will decrease
you app start time

Obviously this package doesn't obfuscate or encrypt config values, but
generated Dart file will be build and obfuscated with rest of
your mobile application code. If you want to secure your sensitive
information you can use encrypted values and **pattern** key to wrap it
with your decrypt library. But overall keep in mind that there is no way
to fully [secure your app from reverse engineering](https://rammic.github.io/2015/07/28/hiding-secrets-in-android-apps/)

Also this package allows to generate `.env` file with same key value pairs

## Config

## Command options

During command run YAML file will be parsed to define keys for command.

- `config` - path to custom yaml file with package configuration
- `config_extension` - name of the extension, that should be used for
  config generation
- any key name, that specified in yaml file under `fields` key
- `dev_extension` key name, allows to use this key as bool flag

For example. If you have next yaml config

```yaml
environment_config:
  fields:
    key_one:
      short_name: o #optional
    key_two:
      short_name: t #optional
```

You will be able tou run command with following options
```
flutter pub run environment_config:generate --key_one=something --key_two=other
```

Or (if `short_name` is specified)
```
flutter pub run environment_config:generate -o something -t other
```

Both commands will generate same dart class

```dart
class EnvironmentConfig {
  static const String key_one = 'something';

  static const String key_two = 'other';
}
```

### Multiple config files

If you want to use different config YAML files for different environment
or you need to generate multiple configurations, use `config` key during
command run

```
flutter pub run environment_config:generate --config=path/to/file.yaml
```

## Class configuration

Class and file can be configured with next options

- `path` - path to file against `lib` folder, by default it's `environment_config.dart`
- `dotenv_path` - path to file against root app folder, by default it's
  `.env`
- `class` - class name, by default will be generated based on file name
- `const` - optional, defines if class constructor should be
defined as `const`.
- `imports` - array of imports to add to generated config file
- `fields`- set of fields, that should be defined in configuration files
- `dev_extension` - defines which extension should be treated as dev
  extension, if specified - it's value can be used during command run as
  bool flag
- `extensions` - set of configurations, that can extend default config

If `class` is not specified value for class name will be generate based
on file name in `path` field. It will convert `snake_case` into
`CamelCase`.

Field `dotenv_path` will be used only if at least one field contains `dotenv: true`

### Config Examples

#### Custom path example

```yaml
environment_config:
  path: config/some_config.dart
  
  ...
```
Will create file with name `some_config.dart` in `lib/config` folder
with following class

```dart
class SomeConfig {
  ///
}
```

#### Custom class name example
```yaml
environment_config:
  path: config/some_other_config_file.dart
  class: OtherClass
  
  ...
```
will create file with name `some_other_config_file.dart` in `lib/config`
folder with following class

```dart
class OtherClass {
  ///
}
```

#### Class with const constructor

```yaml
environment_config:
  class: OtherClass
  const: true
  
  ...
```
will create config with following class

```dart
class OtherClass {
  const OtherClass();
  ///
}
```

If `const` is used it will force class to have const constructor or without it.

## Field configuration

To define fields for config definition, provide key set under `fields` key.

Configuration accepts any amount of field keys. At least one field
should be specified

**Note:** `config` key can't be used for field definition. It's reserved
by command itself to define path to custom config yaml file

**Note** If `dev_extension` is defined, its value can't be used as field
name

Each field accepts next params, each param is **optional**
- `type` - field type, default to `String`
- `const` - if field should be `const`, default to `TRUE`. If `FALSE`, `final` modifier will be used instead
- `static` - if field should be `static`, default to `TRUE`. If `FALSE`,
  `const` option will be ignored
- `pattern` - pattern for field value. Inside value for this field
  `__VALUE__` can be used. It will be replaced with actual entered value
  or with default value
- `default` - default value for the field. If not specified, field will be treated as required
- `short_name` - short key name, that can be used during command run
instead of full field name. Accepts 1 symbol values only
- `dotenv` - bool flag, if `TRUE` this field will be added to `.env` file.
- `env_var` - environment global variable name
- `config_field` - default to `TRUE`, indicates if this field should be
  defined in Dart class config

**If you want to generate `.env` file in addition to class config, at least ONE
key should have `dotenv` to be TRUE. Otherwise `.env` file won't be generated**

**If field contains `dotenv: false` (which is default state) and
`config_field: false` field will be ignored**

**Note** If field config doesn't have `default` key specified it will be
treated as **required**. Which means that you need provide value for
your field in one of the following way:
- argument during command run
- global env variable, if `env_var` is specified

**Note:** If `pattern` key is specified and `const` is `TRUE` ensure your
pattern also contains `const` modifier like this

```yaml
environment_config:
  fields:
    some_key:
      pattern: const CustomClass('__VALUE__')
```

### Fields config examples

#### Pattern example

```yaml
environment_config:
  fields:
    numberValue:
      type: num
      const: false
      short_name: o #optional
    customClassValue:
      type: CustomClass
      pattern: const CustomClass('__VALUE__')
```

This config allows to run next command

```
flutter pub run environment_config:generate -o 345 --customClassValue=something
```

It will generate following class

```dart
class EnvironmentConfig {
  static final num numberValue = 345;

  static const CustomClass customClassValue = const CustomClass('something');
}

```

#### DotEnv example

To create `.env` at least one key should have `dotenv: true` attribute
```yaml
environment_config:
  fields:
    first_key: # define field only in Dart class
      type: num
    second_key:
      dotenv: true # will define field in Dart and in `.env`
    third_key:
      dotenv: true # will define field in `.env`
      config_field: false # will exclude field from Dart config file
```

**Note** If `dotenv: false` and `config_field: false` this field won't
be added to `.env` and Dart config class

This command
```
flutter pub run environment_config:generate --first_key=123 --second_key=456 --third_key=789
```

will generate Dart class config in `lib/` folder

```dart
class EnvironmentConfig {
  const EnvironmentConfig();

  static const num first_key = 123;

  static const String second_key = '456';
}
```

and following `.env` in your root app folder

```
second_key=456
third_key=789
```

#### Global environment variable example

If you want to use value from environment variable, just define key
`env_var`.

```yaml
environment_config:
  fields:
    first_key:
      env_var: PATH
```

In that way generator will try to get value from `PATH` global variable
for your key.

Generator will use next priority:
- value from command arguments
- value from environment variable `PATH`
- value from [Extensions](#extensions) `default` key (if extension was
  used that has `default` key)
- value from `default` key (if it was specified)

## Extensions

Extensions allows you to define set of override rules for fields and
imports.

Primarily extensions are needed to override main configuration and
provide some specific settings for environment like dev. That is why it
allows to override just specific set of configuration keys for specific
field:
- const
- pattern
- default
- env_var

Extension won't override other field keys to keep config class signature
consistent (if you need to add other keys in this list, feel free to
open an issue for that).

Also extension allows you to define import list in addition to default
config. If extension is used - import list will be merged from default
config and extension config

### Basic Extension config usage

To use extension define it in config:

```yaml
environment_config:
  fields:
    first_key:
    
  imports:
    - some:package
      
  extensions:
    dev: # your extension name
      fields:
        first_key:
          default: some value
      
      imports:
        - other:package
```

Then if you run command like this

```
flutter pub run environment_config:generate
```

It will throw an error that `first_key` is required. But you use
extension

```
flutter pub run environment_config:generate --config-extension=dev
```

It will generate following config class

```dart
import 'some:package';
import 'other:package';

class EnvironmentConfig {
  static const String first_key = 'some value';
}
```

### Development Extension example

**Note** Don't use development extension in your automated build tools.
There is a plan add verbose command run support eventually.

Most common case when extension can be used is for your Dev environment.
In that way your default config will ensure that all fields are provided
by build tool, and in same time - to generate config for dev
environment, you won't need to define values for your fields.

To enable dev extension just add `dev_extension`

```diff
environment_config:
  dev_extension: dev # `dev` here is the name of you extension
  fields:
    first_key:
    
  imports:
    - some:package
      
  extensions:
    dev:
      fields:
        first_key:
          default: some value
      
      imports:
        - other:package
```

Then you can run command like this, where `dev` is key name from
`dev_extension`

```
flutter pub run environment_config:generate --dev
```

## Integration with CI/CD

To add config generation into any CI/CD, add command execution after
deps are installed and before build run.

```
flutter pub run environment_config:generate --<key_name>=<key_value>
```

If your build tool allows to specify environment variables (for example
like Code Magic does), you can specify all needed key/values there. And
in YAML config just define `env_var` in keys, where you want to use them
with same variable name like in your build tool. If all keys has
`env_var` specified and your build tool also provides all needed values,
you can run generator just like this.

```
flutter pub run environment_config:generate
```

## Integration with other packages

**Note** Next package was selected just for an example. You can choose any other package
that works with `.env` file

Support of `.env` generation was primarily added to generate config for
packages that relies on it.

For example `.env` generation feature can be used with [flutter_config](https://pub.dev/packages/flutter_config)
package. This particular package allows you to pass environment variables from `.env`
into your native layer like your plugins or Android/iOS app configuration.

For more info see this docs for [Android](https://github.com/ByneappLLC/flutter_config/blob/master/doc/ANDROID.md)
or [iOS](https://github.com/ByneappLLC/flutter_config/blob/master/doc/IOS.md)

## Changelog

Please see the [Changelog](https://github.com/TatsuUkraine/dart_environment_config/blob/master/CHANGELOG.md)
page to know what's recently changed.

## Bugs/Requests

If you encounter any problems feel free to open an [issue](https://github.com/TatsuUkraine/dart_environment_config/issues).
If you feel the library is missing a feature,
please raise a ticket on Github and I'll look into it.
Pull request are also welcome.