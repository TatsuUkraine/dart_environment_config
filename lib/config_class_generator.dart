import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'config.dart';

class ConfigClassGenerator {
  final Config config;

  ConfigClassGenerator(this.config);

  Future<void> generate() async {
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
                    config.fields.map((FieldConfig field) => Field(
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

    File quotesFile = new File(config.filePath);

    await quotesFile.writeAsString(classDefinition, mode: FileMode.write);
  }
}
