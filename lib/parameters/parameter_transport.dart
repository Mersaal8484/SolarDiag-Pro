part of 'write_pipeline.dart';

typedef ParameterReader = Future<num> Function(String id);
typedef ConfigurationReader = Future<Map<String, num>> Function();
typedef ParameterWriter =
    Future<void> Function(String id, int rawValue, String idempotencyKey);

sealed class ParameterTransport {
  ParameterTransport._({
    required this.kind,
    required this._read,
    required this._readAll,
    required this._write,
  });

  factory ParameterTransport.physical({
    required ParameterReader read,
    required ConfigurationReader readAll,
    required ParameterWriter write,
  }) => _PhysicalParameterTransport(read: read, readAll: readAll, write: write);

  factory ParameterTransport.simulator({
    required ParameterReader read,
    required ConfigurationReader readAll,
    required ParameterWriter write,
  }) =>
      _SimulatorParameterTransport(read: read, readAll: readAll, write: write);

  final TransportKind kind;
  final ParameterReader _read;
  final ConfigurationReader _readAll;
  final ParameterWriter _write;

  Future<num> readParameter(String id) => _read(id);
  Future<Map<String, num>> readConfiguration() => _readAll();
  Future<void> _commit(String id, int raw, String key) => _write(id, raw, key);
}

final class _PhysicalParameterTransport extends ParameterTransport {
  _PhysicalParameterTransport({
    required super.read,
    required super.readAll,
    required super.write,
  }) : super._(kind: TransportKind.physical);
}

final class _SimulatorParameterTransport extends ParameterTransport {
  _SimulatorParameterTransport({
    required super.read,
    required super.readAll,
    required super.write,
  }) : super._(kind: TransportKind.simulator);
}
