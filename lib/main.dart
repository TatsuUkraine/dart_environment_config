import 'dart:io';

import 'package:args/args.dart';

import 'errors/config_error.dart';
import 'config_data_provider.dart';
import 'config_class_generator.dart';
import 'config_loader.dart';

const _CONFIG_KEY = 'config';

void generateConfig(List<String> arguments) async {
  ArgParser parser = new ArgParser.allowAnything();

  final ArgResults argResults = parser.parse(arguments);

  String configPath;

  if (argResults.options.contains(_CONFIG_KEY)) {
    configPath = argResults[_CONFIG_KEY];
  }

  try {
    final config = ConfigDataProvider.fromArguments(
      arguments,
      await loadConfig(
        configPath
      )
    );

    await ConfigClassGenerator(config).generate();
    stdout.write('Config generated at "${config.filePath}"');

    exitCode = 0;
  } catch(e) {
    exitCode = 2;

    if (e is! ConfigError) {
      throw e;
    }

    stderr.write(e);
  }
}
