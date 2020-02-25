import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'config.dart';

/// Generates Dart class and `env` file (if it's needed)
class ConfigGenerator {
  final Config config;

  ConfigGenerator(this.config);

  Future<void> generate() {
    List<Future<void>> futures = [
      _generateClass(),
    ];

    if (config.createDotEnv) {
      futures.add(_generateDotEnv());
    }

    return Future.wait(futures);
  }

  Future<void> _generateClass() async {
    List<Constructor> constructors = [];

    if (config.isClassConst) {
      constructors.add(Constructor(
          (ConstructorBuilder builder) => builder..constant = true));
    }

    final Library library =
        Library((LibraryBuilder builder) => builder.body.addAll([
              ...config.imports
                  .map((String import) => Directive.import(import)),
              Class((ClassBuilder builder) => builder
                ..constructors.addAll(constructors)
                ..name = config.className
                ..fields.addAll(config.fields.map((FieldConfig field) => Field(
                      (FieldBuilder builder) => builder
                        ..name = field.name
                        ..static = true
                        ..modifier = field.modifier
                        ..type = Reference(field.type)
                        ..assignment = Code(field.value),
                    )))),
            ]));

    final classDefinition =
        DartFormatter().format('${library.accept(DartEmitter())}');

    final File configFile = File(config.filePath);

    await configFile.writeAsString(classDefinition, mode: FileMode.write);

    stdout.writeln('Config generated at "${config.filePath}"');
  }

  Future<void> _generateDotEnv() async {
    final File configFile = File(config.dotEnvFilePath);

    final String envString = config.dotEnvFields
        .map((field) => '${field.name}=${field.dotEnvValue}')
        .join("\r\n");

    await configFile.writeAsString(envString, mode: FileMode.write);

    stdout.writeln('.env config generated at "${config.dotEnvFilePath}"');
  }
}
