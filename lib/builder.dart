import 'dart:async';

import 'package:build/build.dart';
import 'package:environment_config/generator.dart' as gen;

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
  Future<void> build(BuildStep buildStep) => gen.generateConfig(arguments);
}
