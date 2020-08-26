import 'dart:io';

import 'platform_value_provider.dart';
import 'argument_parser.dart';
import 'config.dart';
import 'config_generator.dart';
import 'config_loader.dart';

/// Entry point of command run
Future<void> generateConfig(List<String> arguments) {
  final parser = ArgumentParser(arguments);

  return loadConfig(parser.parseConfigPath()).then((yamlConfig) {
    return Config.fromMap(
      PlatformValueProvider(),
      yamlConfig,
      parser.parseArguments(yamlConfig),
    );
  }).then((config) {
    return ConfigGenerator(config).generate();
  }).then((_) {
    exitCode = 0;
  }).catchError((e) {
    exitCode = 2;

    stderr.writeln(e);
  });
}
