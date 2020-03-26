import 'errors/extension_not_found_error.dart';
import 'config_field_type.dart';
import 'field_config.dart';
import 'platform_value_provider.dart';

/// Config object that provides parsed
/// params from command
class Config {
  /// Arguments from command
  final Map<String, dynamic> arguments;

  /// Config object from yaml file
  final Map<dynamic, dynamic> config;

  /// Extension config object from yaml file
  final Map<dynamic, dynamic> extConfig;

  final Iterable<FieldConfig> _fields;

  Config(this.config, this.arguments, Iterable<FieldConfig> fields, this.extConfig): _fields = fields;

  factory Config.fromMap(
    PlatformValueProvider valueProvider,
    Map<dynamic, dynamic> config,
    Map<dynamic, dynamic> args
  ) {
    final String devExtension = config[ConfigFieldType.DEV_EXTENSION];
    final Map<dynamic, dynamic> configFields = config[ConfigFieldType.FIELDS];
    final Map<dynamic, dynamic> extensions = config[ConfigFieldType.EXTENSIONS] ?? {};
    Map<dynamic, dynamic> extension = {};
    String extensionName = null;

    if (devExtension != null && args[devExtension]) {
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
        valueProvider,
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
    if (arguments.containsKey(key) && !arguments[key].isEmpty) {
      return arguments[key];
    }

    if (config.containsKey(key) && !(config[key] ?? '').isEmpty) {
      return config[key];
    }

    return defaultValue;
  }
}
