import 'dart:io';

import 'argument_parser.dart';
import 'errors/config_error.dart';
import 'config.dart';
import 'config_generator.dart';
import 'config_loader.dart';

/// Entry point of command run
void generateConfig(List<String> arguments) async {
  final parser = ArgumentParser(arguments);

  try {
    final yamlConfig = await loadConfig(parser.parseConfigPath());

    final config = Config(yamlConfig, parser.parseArguments(yamlConfig));

    await ConfigGenerator(config).generate();

    exitCode = 0;
  } catch (e) {
    exitCode = 2;

    if (e is! ConfigError) {
      throw e;
    }

    stderr.write(e);
  }
}
