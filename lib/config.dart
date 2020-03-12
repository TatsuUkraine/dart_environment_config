import 'package:args/args.dart';
import 'package:code_builder/code_builder.dart';

import 'errors/validation_error.dart';
import 'config_field_type.dart';

final RegExp _PATTERN_REGEXP = RegExp(r'__VALUE__');

/// Config object that provides parsed
/// params from command
class Config {
  /// Arguments from command
  final ArgResults arguments;

  /// Config object from yaml file
  final Map<dynamic, dynamic> config;

  final Iterable<FieldConfig> _fields;

  Config(this.config, this.arguments)
      : _fields = (config[ConfigFieldType.FIELDS] as Map<dynamic, dynamic>)
            .keys
            .map((key) => FieldConfig(key,
                config[ConfigFieldType.FIELDS][key] ?? {}, arguments[key]));

  /// Target file for generated config class
  String get filePath {
    return 'lib/${_getConfigValue(ConfigFieldType.PATH, 'environment_config.dart')}';
  }

  /// Target file for `.env` params
  String get dotEnvFilePath {
    return _getConfigValue(ConfigFieldType.DOTENV_PATH, '.env');
  }

  /// Provides config class name
  String get className {
    String className = _getConfigValue(ConfigFieldType.CLASS);

    if (className != null) {
      return className;
    }

    final String fileName =
        RegExp(r'\/([\w_-]+)\.dart$').firstMatch(filePath).group(1);

    return fileName
        .split('_')
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join('');
  }

  /// Fields, that should be exported to `.env` file
  Iterable<FieldConfig> get dotEnvFields {
    return _fields.where((field) => field.isDotEnv);
  }

  /// Fields, that should be exported to Dart config file
  Iterable<FieldConfig> get classConfigFields {
    return _fields.where((field) => field.isConfigField);
  }

  /// Collection if imports, that should be added to config class
  Iterable<String> get imports {
    if (!config.containsKey(ConfigFieldType.IMPORTS)) {
      return [];
    }

    final List<dynamic> imports = config[ConfigFieldType.IMPORTS];

    return imports?.map((f) => f as String) ?? [];
  }

  /// If class should contain `const` constructor
  bool get isClassConst => config[ConfigFieldType.CONST] ?? false;

  /// Defines if generator should try to create `.env` file
  bool get createDotEnv => dotEnvFields.isNotEmpty;

  /// Defines if generator should try to create Dart config file
  bool get createConfigClass => classConfigFields.isNotEmpty;

  String _getConfigValue(key, [String defaultValue]) {
    if (arguments.arguments.contains(key) && !arguments[key].isEmpty) {
      return arguments[key];
    }

    if (config.containsKey(key) && !(config[key] ?? '').isEmpty) {
      return config[key];
    }

    return defaultValue;
  }
}

class FieldConfig {
  /// Field name
  final String name;

  /// Field configuration from YAML file
  final Map<dynamic, dynamic> field;

  /// Value provided from command params
  final String _value;

  FieldConfig(this.name, this.field, [String value]) : _value = value {
    if (_fieldValue == null) {
      throw ValidationError(name, '"$name" is required');
    }
  }

  /// Field type
  ///
  /// Default to `String`
  String get type => field[ConfigFieldType.TYPE] ?? 'String';

  /// Field modifier
  ///
  /// If field is `const` provides Field builder modifier
  FieldModifier get modifier {
    if (isConst) {
      return FieldModifier.constant;
    }

    return FieldModifier.final$;
  }

  /// Defines if field should be `const` or not
  ///
  /// If key not specified field will be treated as `const` by default
  bool get isConst {
    if (!isStatic) {
      return false;
    }

    return field[ConfigFieldType.CONST] ?? true;
  }

  bool get isStatic => field[ConfigFieldType.STATIC] ?? true;

  /// Defines if this field should be exported to `.env` file
  bool get isDotEnv => field[ConfigFieldType.IS_DOTENV] ?? false;

  /// Defines if this field should be exported to Dart config file
  bool get isConfigField => field[ConfigFieldType.CONFIG_FIELD] ?? true;

  /// Get value for config class
  ///
  /// If `pattern` is specified, value will injected into it
  String get value {
    String pattern = _pattern;

    if (_pattern == null && type == 'String') {
      pattern = '\'__VALUE__\'';
    }

    if (pattern == null) {
      return _fieldValue;
    }

    return pattern.replaceAll(_PATTERN_REGEXP, _fieldValue);
  }

  /// Value for key in `.env` file
  String get dotEnvValue {
    return _pattern?.replaceAll(_PATTERN_REGEXP, _fieldValue) ?? _fieldValue;
  }

  String get _pattern => field[ConfigFieldType.PATTERN];

  String get _fieldValue => _value ?? field[ConfigFieldType.DEFAULT];
}
