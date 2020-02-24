import 'dart:io';

import 'package:environment_config/argument_parser.dart';

import 'errors/config_error.dart';
import 'config.dart';
import 'config_class_generator.dart';
import 'config_loader.dart';

void generateConfig(List<String> arguments) async {
  final parser = ArgumentParser(arguments);

  try {
    final yamlConfig = await loadConfig(parser.parseConfigPath());

    final config = Config(
      yamlConfig,
      parser.parseArguments(yamlConfig)
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
