import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:environment_config/argument_parser.dart';
import 'package:environment_config/config.dart';
import 'package:environment_config/config_generator.dart';
import 'package:environment_config/config_loader.dart';
import 'package:environment_config/platform_value_provider.dart';

Builder generateConfig(BuilderOptions builderOptions) =>
    _GenerateConfig(builderOptions);

class _GenerateConfig extends Builder {
  final List<String> arguments;

  _GenerateConfig(BuilderOptions builderOptions)
      : arguments = builderOptions.config.entries
            .map((e) => e.value != null ? '${e.key}=${e.value}' : e.key)
            .toList(growable: false);

  @override
  final buildExtensions = const {
    '.yaml': ['.dart']
  };

  @override
  FutureOr<void> build(BuildStep buildStep) {
    final parser = ArgumentParser(arguments);

    return loadConfig(parser.parseConfigPath())
        .then((yamlConfig) => Config.fromMap(
              PlatformValueProvider(),
              yamlConfig,
              parser.parseArguments(yamlConfig),
            ))
        .then((config) => ConfigGenerator(config).generate())
        .then((_) {
      exitCode = 0;
    }).catchError((e) {
      exitCode = 2;

      stderr.writeln(e);
    });
  }
}
