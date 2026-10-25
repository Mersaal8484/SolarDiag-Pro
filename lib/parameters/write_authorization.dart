part of '../protocols/modbus/modbus_client.dart';

final class PipelineWriteAuthorization {
  PipelineWriteAuthorization._({
    required this.functionCode,
    required this.address,
    required this.count,
    required this.valueHash,
    required this.expiresAt,
  });

  final int functionCode;
  final int address;
  final int count;
  final String valueHash;
  final DateTime expiresAt;
  bool _used = false;

  bool _consume({
    required int functionCode,
    required int address,
    required List<int> values,
    required DateTime now,
  }) {
    if (_used ||
        !now.isBefore(expiresAt) ||
        this.functionCode != functionCode ||
        this.address != address ||
        count != values.length ||
        valueHash != _modbusValueHash(values)) {
      return false;
    }
    _used = true;
    return true;
  }
}

PipelineWriteAuthorization mintPipelineWriteAuthorization({
  required int functionCode,
  required int address,
  required List<int> values,
  required AuthorizationController authorizationController,
  required DeviceWriteContext context,
  required ConfirmationToken confirmation,
  required String shownPlanHash,
  required bool safetyAcknowledged,
  required AuditChain audit,
  DateTime Function()? clock,
}) {
  final now = (clock ?? DateTime.now)().toUtc();
  final authorization = authorizationController.current;
  if (audit.availability != AuditAvailability.available) {
    throw StateError('Audit key unavailable; Modbus write is locked.');
  }
  if (functionCode != ModbusFunction.writeMultipleRegisters.code ||
      address < 0 ||
      address > 0xffff ||
      values.isEmpty ||
      values.length > 123 ||
      values.any((value) => value < 0 || value > 0xffff)) {
    throw ArgumentError('Invalid Modbus write request.');
  }
  if (authorization == null ||
      !authorization.isValidAt(now) ||
      authorization.tier.index < AuthorizationTier.technician.index ||
      context.writeLocked ||
      !context.exactIdentityMatch ||
      !context.linkHealthy ||
      !safetyAcknowledged ||
      shownPlanHash.isEmpty ||
      !confirmation.consume(
        expectedHash: shownPlanHash,
        context: context,
        now: now,
      )) {
    throw StateError('Verified pipeline rejected the Modbus write.');
  }
  final valueHash = _modbusValueHash(values);
  audit.append('modbus_write_authorized', {
    'function': functionCode,
    'address': address,
    'count': values.length,
    'value_hash': valueHash,
  });
  return PipelineWriteAuthorization._(
    functionCode: functionCode,
    address: address,
    count: values.length,
    valueHash: valueHash,
    expiresAt: confirmation.expiresAt,
  );
}

String _modbusValueHash(List<int> values) =>
    sha256.convert(utf8.encode(jsonEncode(values))).toString();
