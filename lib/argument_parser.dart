import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'config_field_type.dart';
import 'errors/malformed_config_error.dart';
import 'errors/validation_error.dart';

/// Command argument parser
class ArgumentParser {
  /// Arguments from command params
  final List<String> arguments;

  ArgumentParser(this.arguments);

  /// Defines if `config` key was specified
  /// during command run
  String? parseConfigPath() {
    ArgParser parser = ArgParser()..addOption(ConfigFieldType.CONFIG);

    final ArgResults argResults = parser.parse(
        arguments.where((arg) => arg.contains('--${ConfigFieldType.CONFIG}=')));

    if (!argResults.options.contains(ConfigFieldType.CONFIG)) {
      return null;
    }

    return argResults[ConfigFieldType.CONFIG];
  }

  /// Provides arguments from command based on YAML fields config
  Map<String, dynamic> parseArguments(YamlMap config) {
    final ArgParser parser = ArgParser();

    if (!config.containsKey(ConfigFieldType.FIELDS)) {
      throw MalformedConfigError('"fields" key is missing');
    }

    if (config[ConfigFieldType.FIELDS] == null) {
      throw ValidationError(
          ConfigFieldType.FIELDS, 'At least one field should be specified');
    }

    final params = config[ConfigFieldType.FIELDS];

    if (config.containsKey(ConfigFieldType.DEV_EXTENSION)) {
      parser.addFlag(config[ConfigFieldType.DEV_EXTENSION]);
    }

    parser
      ..addOption(ConfigFieldType.CONFIG)
      ..addOption(ConfigFieldType.CONFIG_EXTENSION);

    params.keys.forEach((key) {
      if (params[key] != null && params[key] is! Map) {
        throw MalformedConfigError('Malformed config');
      }

      final Map<dynamic, dynamic> value = params[key] ?? {};

      parser.addOption(
        key,
        abbr: value[ConfigFieldType.SHORT_NAME],
      );
    });

    final ArgResults parsedArguments = parser.parse(arguments);

    return {
      for (String key in parsedArguments.options) key: parsedArguments[key],
    };
  }
}
