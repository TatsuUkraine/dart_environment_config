import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import 'config_field.dart';
import 'errors/malformed_config_error.dart';

class ArgumentParser {

  final List<String> arguments;

  ArgumentParser(this.arguments);

  String parseConfigPath() {
    ArgParser parser = new ArgParser()
      ..addOption(ConfigField.CONFIG);

    final ArgResults argResults = parser.parse(
        arguments.where((arg) => arg.contains('--${ConfigField.CONFIG}='))
    );

    if (!argResults.options.contains(ConfigField.CONFIG)) {
      return null;
    }

    return argResults[ConfigField.CONFIG];
  }

  ArgResults parseArguments(YamlMap config) {
    final ArgParser parser = new ArgParser();

    if (!config.containsKey(ConfigField.FIELDS)) {
      throw MalformedConfigError('"fields" key is missing');
    }

    final params = config[ConfigField.FIELDS];

    parser.addOption(ConfigField.CONFIG);

    params.keys.forEach((key) {
      if (params[key] is! YamlMap) {
        throw MalformedConfigError('Mailformed config');
      }

      final YamlMap value = params[key];

      parser.addOption(
        key,
        abbr: value[ConfigField.SHORT_NAME],
        defaultsTo: value[ConfigField.DEFAULT],
      );
    });

    return parser.parse(arguments);
  }
}