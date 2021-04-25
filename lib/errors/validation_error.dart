import 'config_error.dart';

class ValidationError extends ConfigError {
  final String field;
  final String? message;

  ValidationError(this.field, [this.message]);

  @override
  String toString() {
    return 'ValidationError[$field]: $message';
  }
}
