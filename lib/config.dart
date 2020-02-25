import 'package:args/args.dart';
import 'package:code_builder/code_builder.dart';

import 'errors/validation_error.dart';
import 'config_field_type.dart';

final RegExp _PATTERN_REGEXP = RegExp(r'__VALUE__');

class Config {
  final ArgResults arguments;
  final Map<dynamic, dynamic> config;

  Config(this.config, this.arguments);

  String get filePath {
    return 'lib/${_getConfigValue(ConfigFieldType.PATH, 'environment_config.dart')}';
  }

  String get dotEnvFilePath {
    return 'lib/${_getConfigValue(ConfigFieldType.DOTENV_PATH, '.env')}';
  }

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

  Iterable<FieldConfig> get fields {
    final Map<dynamic, dynamic> fields = config[ConfigFieldType.FIELDS];

    return fields.keys.map((key) => FieldConfig(
        key, config[ConfigFieldType.FIELDS][key] ?? {}, arguments[key]));
  }

  Iterable<FieldConfig> get dotEnvFields {
    return fields.where((field) => field.isDotEnv);
  }

  Iterable<String> get imports {
    if (!config.containsKey(ConfigFieldType.IMPORTS)) {
      return [];
    }

    final List<dynamic> imports = config[ConfigFieldType.IMPORTS];

    return imports?.map((f) => f as String) ?? [];
  }

  bool get isClassConst {
    if (config.containsKey(ConfigFieldType.CONST)) {
      return config[ConfigFieldType.CONST];
    }

    return fields.every((field) => field.isConst);
  }

  bool get createDotEnv => dotEnvFields.length > 0;

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
  final String name;
  final Map<dynamic, dynamic> field;
  final String _value;

  FieldConfig(this.name, this.field, [String value]) : _value = value {
    if ((_value ?? field[ConfigFieldType.DEFAULT] ?? '').isEmpty) {
      throw ValidationError(name, '"$name" is required');
    }
  }

  String get type => field[ConfigFieldType.TYPE] ?? 'String';

  FieldModifier get modifier {
    if (isConst) {
      return FieldModifier.constant;
    }

    return FieldModifier.final$;
  }

  bool get isConst => field[ConfigFieldType.CONST] ?? true;

  bool get isDotEnv => field[ConfigFieldType.IS_DOTENV] ?? false;

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

  String get dotEnvValue {
    return _pattern?.replaceAll(_PATTERN_REGEXP, _fieldValue) ?? _fieldValue;
  }

  String get _pattern => field[ConfigFieldType.PATTERN];

  String get _fieldValue => _value ?? field[ConfigFieldType.DEFAULT];
}
