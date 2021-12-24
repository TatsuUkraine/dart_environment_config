import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'config.dart';
import 'config_field_type.dart';
import 'errors/validation_error.dart';
import 'field_config.dart';

/// Generates Dart class and `env` file (if it's needed)
class ConfigGenerator {
  final Config config;

  ConfigGenerator(this.config);

  Future<void> generate() {
    List<Future<void>> futures = [];

    if (config.createConfigClass) {
      futures.add(_generateClass());
    }

    if (config.createRcFile) {
      futures.add(_generateRcFile());
    }

    if (futures.isEmpty) {
      throw ValidationError(ConfigFieldType.FIELDS,
          'At least one field should be defined for RC or Dart config class');
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
                ..fields.addAll(
                    config.classConfigFields.map((FieldConfig field) => Field(
                          (FieldBuilder builder) => builder
                            ..name = field.name
                            ..static = field.isStatic
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

  Future<void> _generateRcFile() async {
    final File configFile = File(config.rcFilePath);

    final String envString = config.rcFields
        .map((field) => '${field.name}=${field.rcValue}')
        .join("\r\n");

    await configFile.writeAsString(envString, mode: FileMode.write);

    stdout.writeln('RC config generated at "${config.rcFilePath}"');
  }
}
