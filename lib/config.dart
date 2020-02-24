import 'package:args/args.dart';
import 'package:code_builder/code_builder.dart';
import 'package:yaml/yaml.dart';

import 'errors/validation_error.dart';
import 'config_field.dart';

class Config {

  final ArgResults arguments;
  final YamlMap config;

  Config(this.config, this.arguments);

  String get filePath {
    return 'lib/${_getConfigValue(ConfigField.PATH, 'environment_config.dart')}';
  }

  String get className {
    String className = _getConfigValue(ConfigField.CLASS);

    if (className != null) {
      return className;
    }

    final String fileName = RegExp(r'\/([\w_-]+)\.dart$').firstMatch(filePath).group(1);

    return fileName.split('_')
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join('');
  }

  Iterable<FieldDataProvider> get fields {
    final YamlMap fields = config[ConfigField.FIELDS];

    return fields.keys.map((key) => FieldDataProvider(
      key,
      config[ConfigField.FIELDS][key],
      arguments[key]
    ));
  }

  Iterable<String> get imports {
    if (!config.containsKey(ConfigField.IMPORTS)) {
      return [];
    }

    final YamlList imports = config[ConfigField.IMPORTS];

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

  final String name;
  final YamlMap field;
  final String _value;

  FieldDataProvider(this.name, this.field, [String value]): _value = value {
    if ((_value ?? field[ConfigField.DEFAULT] ?? '').isEmpty) {
      throw ValidationError(name, '"$name" is required');
    }
  }

  String get type => field[ConfigField.TYPE] ?? 'String';

  FieldModifier get modifier {
    if (field[ConfigField.CONST] ?? true) {
      return FieldModifier.constant;
    }

    return FieldModifier.final$;
  }

  String get _pattern {
    if (field.containsKey(ConfigField.PATTERN)) {
      return field[ConfigField.PATTERN];
    }

    if (type != 'String') {
      return null;
    }

    return '\'__VALUE__\'';
  }

  String get value {
    String value = _value ?? field[ConfigField.DEFAULT];

    if (_pattern == null) {
      return value;
    }

    return _pattern.replaceAll(new RegExp(r'__VALUE__'), value);
  }
}