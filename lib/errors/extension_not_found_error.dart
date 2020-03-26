import 'config_error.dart';

class ExtensionNotFound extends ConfigError {
  final String extensionName;

  ExtensionNotFound(this.extensionName);

  @override
  String toString() {
    return 'ExtensionNotFound: "$extensionName" extension not found';
  }
}
