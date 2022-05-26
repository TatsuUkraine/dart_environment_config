import 'package:code_builder/code_builder.dart';

import 'config_field_type.dart';
import 'errors/validation_error.dart';
import 'platform_value_provider.dart';

final RegExp _PATTERN_REGEXP = RegExp(r'__VALUE__');

class FieldConfig {
  /// Field name
  final String name;

  /// Field configuration from YAML file
  final Map<dynamic, dynamic> field;

  /// Field configuration from YAML file
  final Map<dynamic, dynamic> extField;

  /// Value provided from command params
  final String? _value;

  final PlatformValueProvider _valueProvider;

  FieldConfig(
      PlatformValueProvider valueProvider, this.name, this.field, this.extField,
      [String? value])
      : _value = value,
        _valueProvider = valueProvider {
    if (!_nullable && _fieldValue == null) {
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

    return extField[ConfigFieldType.CONST] ??
        field[ConfigFieldType.CONST] ??
        true;
  }

  /// Is Field should be defined as STATIC
  bool get isStatic => field[ConfigFieldType.STATIC] ?? true;

  /// Defines if this field should be exported to `.env` file
  bool get isDotEnv => field[ConfigFieldType.IS_DOTENV] ?? false;

  /// Defines if this field should be exported to Dart config file
  bool get isConfigField => field[ConfigFieldType.CONFIG_FIELD] ?? true;

  /// Get value for config class
  ///
  /// If `pattern` is specified, value will injected into it
  String get value {
    String? pattern = _pattern;

    if (pattern == null && _isStringType) {
      pattern = '\'__VALUE__\'';
    }

    if (_nullable && (_fieldValue == null || _fieldValue == 'null')) {
      return 'null';
    }

    if (pattern == null) {
      return _fieldValue!;
    }

    return pattern.replaceAll(_PATTERN_REGEXP, _fieldValue!);
  }

  /// Value for key in `.env` file
  String get dotEnvValue =>
      _pattern?.replaceAll(_PATTERN_REGEXP, _fieldValue!) ?? _fieldValue!;

  String? get _pattern =>
      extField[ConfigFieldType.PATTERN] ?? field[ConfigFieldType.PATTERN];

  String? get _globalValue {
    final String? globalKey =
        extField[ConfigFieldType.ENV_VAR] ?? field[ConfigFieldType.ENV_VAR];

    if ((globalKey ?? '').isNotEmpty) {
      return _valueProvider.getValue(globalKey!);
    }

    return null;
  }

  String? get _fieldValue => (_value ??
          _globalValue ??
          extField[ConfigFieldType.DEFAULT] ??
          field[ConfigFieldType.DEFAULT])
      ?.toString();

  bool get _nullable => type.contains(RegExp(r'\?$'));

  bool get _isStringType => const ['String', 'String?'].contains(type);
}
