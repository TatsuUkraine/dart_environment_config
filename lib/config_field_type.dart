/// Set of fields used in YAML document
class ConfigFieldType {
  static const String CONFIG = 'config';
  static const String CONFIG_EXTENSION = 'config-extension';
  static const String FIELDS = 'fields';
  static const String IMPORTS = 'imports';
  static const String CLASS = 'class';
  static const String PATH = 'path';
  static const String RC_PATH = 'rc_path';
  static const String DEV_EXTENSION = 'dev_extension';
  static const String EXTENSIONS = 'extensions';

  static const String TYPE = 'type';
  static const String PATTERN = 'pattern';
  static const String DEFAULT = 'default';
  static const String CONST = 'const';
  static const String SHORT_NAME = 'short_name';
  static const String EXPORT_TO_RC = 'export_to_rc';
  static const String ENV_VAR = 'env_var';
  static const String CONFIG_FIELD = 'config_field';
  static const String STATIC = 'static';

  static const List<String> EXTENDED_CONFIG_FIELDS = [
    PATH,
    RC_PATH,
    CLASS,
  ];
}
