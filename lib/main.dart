import 'dart:io';

import 'package:args/args.dart';

import 'errors/config_error.dart';
import 'config_data_provider.dart';
import 'config_class_generator.dart';
import 'config_loader.dart';

void generateConfig(List<String> arguments) async {
  ArgParser parser = new ArgParser()
    ..addOption(ConfigDataProvider.CONFIG_COMMAND_KEY);

  final ArgResults argResults = parser.parse(
    arguments.where((arg) => arg.contains('--${ConfigDataProvider.CONFIG_COMMAND_KEY}='))
  );

  String configPath;

  if (argResults.options.contains(ConfigDataProvider.CONFIG_COMMAND_KEY)) {
    configPath = argResults[ConfigDataProvider.CONFIG_COMMAND_KEY];
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
