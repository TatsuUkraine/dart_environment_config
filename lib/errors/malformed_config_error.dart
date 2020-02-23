import 'config_error.dart';

class MalformedConfigError extends ConfigError {
  final String message;

  MalformedConfigError(this.message);

  @override
  String toString() {
    return 'MalformedConfig: $message';
  }
}