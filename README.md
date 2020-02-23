# environment_config

Environment specific config generator.

Allows to specify env configuration during CI&#x2F;CD build.

Primarily created to simplify Flutter build configuration.

## Features

- flexible configuration for Config class generation
- allows to specify pattern for field values
- allows to define required and optional keys for generation

## Getting Started

Install package as dependency.

Create `environment_config.yaml` or update `package.yaml` file with following code

```yaml
environment_config:
  path: lib/environment_config.dart # optional, result file path
  class: EnvironmentConfig # optional, class name
  
  fields: # set of fields for command
    some_key: # key name
      type: # optional, default to 'String'
      short_name: # optional, short name for key during command run
      const: # optional, default to TRUE
      pattern: # optional, specified pattern for key value, use __VALUE__ to insert entered value anywhere in the pattern
      default: # optional, default value for key, if not provided key will be required during command run
      
  imports: # optional, array of imports, to include in config file
    - package:some_package
```

After config is specified in YAML file run following command

```
pub run environment_config:generate --some_key=some_value
```
Or for flutter project

```
flutter pub run environment_config:generate --some_key=some_value
```

This command with generate file, that was specified in `path` key with
class with fields and name specified in yaml config.

## Config

### Command options

During command run YAML file will be parsed to define keys for command.

- `config` - path to yaml file with package configuration
- any key name, that specified in yaml file under `fields` key

For example. If you will have next yaml config

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

