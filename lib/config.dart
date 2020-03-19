import 'package:args/args.dart';
import 'package:code_builder/code_builder.dart';

import 'errors/extension_not_found_error.dart';
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

  /// Extension config object from yaml file
  final Map<dynamic, dynamic> extConfig;

  final Iterable<FieldConfig> _fields;

  Config(this.config, this.arguments, Iterable<FieldConfig> fields, this.extConfig): _fields = fields;

  factory Config.fromMap(Map<dynamic, dynamic> config, ArgResults args) {
    final String devExtension = config[ConfigFieldType.DEV_EXTENSION] ?? 'dev';
    final Map<dynamic, dynamic> configFields = config[ConfigFieldType.FIELDS];
    final Map<dynamic, dynamic> extensions = config[ConfigFieldType.EXTENSIONS] ?? {};
    Map<dynamic, dynamic> extension = {};
    String extensionName = null;

    if (args[devExtension]) {
      extensionName = devExtension;
    }

    extensionName ??= args[ConfigFieldType.CONFIG_EXTENSION];

    if (extensionName != null) {
      if (!extensions.containsKey(extensionName)) {
        throw ExtensionNotFound(extensionName);
      }

      extension = extensions[extensionName] ?? {};
    }

    Map<dynamic, dynamic> extensionFields = extension[ConfigFieldType.FIELDS] ?? {};

    final Iterable<FieldConfig> fields = configFields.keys
      .map((key) => FieldConfig(
        key,
        config[ConfigFieldType.FIELDS][key] ?? {},
        extensionFields[key] ?? {},
        args[key]
      ));

    return Config(config, args, fields, extension);
  }

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
  Iterable<String> get imports => [
    ...(config[ConfigFieldType.IMPORTS]?.toList() ?? []),
    ...(extConfig[ConfigFieldType.IMPORTS]?.toList() ?? []),
  ];

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

  /// Field configuration from YAML file
  final Map<dynamic, dynamic> extField;

  /// Value provided from command params
  final String _value;

  FieldConfig(this.name, this.field, this.extField, [String value]) : _value = value {
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

    return extField[ConfigFieldType.CONST] ?? field[ConfigFieldType.CONST] ?? true;
  }

  /// Is Field should be defined as STATIC
  bool get isStatic => extField[ConfigFieldType.STATIC] ?? field[ConfigFieldType.STATIC] ?? true;

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

  String get _pattern => extField[ConfigFieldType.PATTERN] ?? field[ConfigFieldType.PATTERN];

  String get _fieldValue => _value ?? extField[ConfigFieldType.DEFAULT] ?? field[ConfigFieldType.DEFAULT];
}
