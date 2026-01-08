class Result<T> {
  final T? _value;
  final Exception? _error;

  Result._(this._value, this._error);

  factory Result.success(T value) => Result._(value, null);

  factory Result.failure(Exception error) => Result._(null, error);

  bool get isSuccess => _error == null;

  bool get isFailure => _error != null;

  T get value {
    final error = _error;
    if (error != null) {
      throw error;
    }
    return _value as T;
  }

  Exception get error {
    final error = _error;
    if (error == null) {
      throw StateError('Result is successful, no error available');
    }
    return error;
  }

  R fold<R>(R Function(Exception error) onFailure, R Function(T value) onSuccess) {
    final error = _error;
    if (error != null) {
      return onFailure(error);
    }
    return onSuccess(_value as T);
  }

  Result<R> map<R>(R Function(T value) transform) {
    final error = _error;
    if (error != null) {
      return Result.failure(error);
    }
    try {
      return Result.success(transform(_value as T));
    } catch (e) {
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    final error = _error;
    if (error != null) {
      return Result.failure(error);
    }
    return transform(_value as T);
  }

  T getOrElse(T Function() defaultValue) {
    if (_error != null) {
      return defaultValue();
    }
    return _value as T;
  }

  T? getOrNull() => _value;

  Exception? get errorOrNull => _error;
}
