import 'package:args/args.dart';
import 'package:code_builder/code_builder.dart';
import 'package:yaml/yaml.dart';

import 'errors/malformed_config_error.dart';
import 'errors/validation_error.dart';

class ConfigDataProvider {
  static const String CONFIG_COMMAND_KEY = 'config';

  static const String _FIELDS_KEY = 'fields';
  static const String _PATH_KEY = 'path';
  static const String _SHORT_NAME_KEY = 'short_name';
  static const String _IMPORTS_KEY = 'imports';

  final ArgResults arguments;
  final YamlMap config;

  ConfigDataProvider(this.config, this.arguments);

  factory ConfigDataProvider.fromArguments(List<String> arguments, YamlMap config) {
    final ArgParser parser = new ArgParser();

    if (!config.containsKey(_FIELDS_KEY)) {
      throw MalformedConfigError('"params" key is missing');
    }

    final params = config[_FIELDS_KEY];

    parser.addOption(CONFIG_COMMAND_KEY);

    params.keys.forEach((key) {
      if (params[key] is! YamlMap) {
        throw MalformedConfigError('Mailformed config');
      }

      final YamlMap value = params[key];

      parser.addOption(
        key,
        abbr: value[_SHORT_NAME_KEY],
        defaultsTo: value[FieldDataProvider._DEFAULT_KEY],
      );
    });

    return ConfigDataProvider(
      config,
      parser.parse(arguments)
    );
  }

  String get filePath => _getConfigValue(_PATH_KEY, 'lib/environment_config.dart');

  String get className {
    String className = _getConfigValue('class');

    if (className != null) {
      return className;
    }

    final String fileName = RegExp(r'/(.*)\.dart$').firstMatch(filePath).group(1);

    return fileName.split('_')
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join('');
  }

  Iterable<FieldDataProvider> get fields {
    final YamlMap fields = config[_FIELDS_KEY];

    return fields.keys.map((key) => FieldDataProvider(
      key,
      config[_FIELDS_KEY][key],
      arguments[key]
    ));
  }

  Iterable<String> get imports {
    if (!config.containsKey(_IMPORTS_KEY)) {
      return [];
    }

    final YamlList imports = config[_IMPORTS_KEY];

    return imports?.map((f) => f as String) ?? [];
  }

  String _getConfigValue(key, [String defaultValue]) {
    if (arguments.arguments.contains(key)) {
      return arguments[key];
    }

    if (config.containsKey(key)) {
      return config[key];
    }

    return defaultValue;
  }
}

class FieldDataProvider {
  static const String _TYPE_KEY = 'type';
  static const String _PATTERN_KEY = 'pattern';
  static const String _DEFAULT_KEY = 'default';
  static const String _CONST_KEY = 'const';

  final String name;
  final YamlMap field;
  final String _value;

  FieldDataProvider(this.name, this.field, [String value]): _value = value {
    if ((_value ?? field[_DEFAULT_KEY] ?? '').isEmpty) {
      throw ValidationError(name, '"$name" is required');
    }
  }

  String get type => field[_TYPE_KEY] ?? 'String';

  FieldModifier get modifier {
    if (field[_CONST_KEY] ?? true) {
      return FieldModifier.constant;
    }

    return FieldModifier.final$;
  }

  String get _pattern {
    if (field.containsKey(_PATTERN_KEY)) {
      return field[_PATTERN_KEY];
    }

    if (type != 'String') {
      return null;
    }

    return '\'__VALUE__\'';
  }

  String get value {
    String value = _value ?? field[_DEFAULT_KEY];

    if (_pattern == null) {
      return value;
    }

    return _pattern.replaceAll(new RegExp(r'__VALUE__'), value);
  }
}