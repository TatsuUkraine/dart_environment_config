import 'dart:io';

import 'package:yaml/yaml.dart';

import 'errors/file_not_found_error.dart';

const List<String> _CONFIG_FILES = [
  'environment_config.yaml',
  'pubspec.yaml',
];

const String _CONFIG_KEY = 'environment_config';

/// Loads config YAML file
///
/// If `config` key provided will try to find file based on this path
///
/// If it's not provided or not found will try to find config in following files
///
/// - <custom_path>
/// - environment_config.yaml
/// - pubspec.yaml
///
/// If no config file found will throw exception
Future<YamlMap> loadConfig(String? path) async {
  List<String> files = [..._CONFIG_FILES];

  if (path != null) {
    files = [
      path,
      ...files,
    ];
  }

  for (String file in files) {
    String yamlString;

    try {
      yamlString = await File(file).readAsString();
    } catch (e) {
      continue;
    }

    final YamlMap? config = loadYaml(yamlString);

    if (config == null) {
      continue;
    }

    if (!config.containsKey(_CONFIG_KEY)) {
      continue;
    }

    return config[_CONFIG_KEY];
  }

  throw FileNotFoundError();
}
