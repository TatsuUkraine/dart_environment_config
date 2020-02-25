import 'config_error.dart';

class FileNotFoundError extends ConfigError {
  @override
  String toString() {
    return 'FileNotFoundError: Config not found';
  }
}
