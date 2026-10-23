import 'dart:async';

import 'modbus_guard.dart';
import 'modbus_models.dart';

/// Thrown when [ModbusClient] rejects a request because [ModbusGuard] does not
/// permit the operation. This is a programming-time safety gate; it must never
/// be silently ignored by callers.
class ModbusGuardException implements Exception {
  const ModbusGuardException(this.reason);
  final String reason;
  @override
  String toString() => 'ModbusGuardException: $reason';
}

/// Raised when a Modbus request is not answered within the configured timeout.
class ModbusTimeout implements Exception {
  const ModbusTimeout();
  @override
  String toString() => 'Modbus request timed out.';
}

/// A Modbus client that wraps a [ModbusGuard] to enforce read/write permissions
/// before any transport-layer I/O occurs.
///
/// Two synchronous guard-check helpers ([checkRead] / [checkWrite]) allow unit
/// tests to verify the permission logic without needing a live transport.
/// The async [readRegisters] / [writeRegisters] methods call those checks first,
/// then delegate to the provided transport callback.
///
/// **Write gate (C2):** a write request is blocked unless ALL of:
///   1. [ModbusGuard.writeVerifiedOnHardware] is `true`, AND
///   2. [pipelineAuthorized] is `true`, AND
///   3. the address/count falls within [ModbusGuard.writeRanges].
class ModbusClient {
  const ModbusClient({
    required this.guard,
    required this.timeout,
    this.transport,
  });

  final ModbusGuard guard;
  final Duration timeout;

  /// Optional transport backend. When `null`, [readRegisters] and
  /// [writeRegisters] throw [ModbusTimeout] after guard-check passes (test mode).
  final Future<List<int>> Function({
    required int address,
    required int count,
    required int unitId,
    required bool isWrite,
    List<int>? values,
  })?
  transport;

  // ── Synchronous guard-check helpers ─────────────────────────────────────

  /// Validates that a read of [count] registers starting at [address] for
  /// [unitId] is permitted by [guard]. Throws [ModbusGuardException] if not.
  void checkRead({
    required int address,
    required int count,
    required int unitId,
  }) {
    final allowed = guard.allows(
      function: ModbusFunction.readHoldingRegisters,
      address: address,
      count: count,
      pipelineAuthorized: true, // reads never need pipeline auth
    );
    if (!allowed) {
      throw ModbusGuardException(
        'Read of $count register(s) at $address (unit $unitId) '
        'is not permitted by the active guard.',
      );
    }
  }

  /// Validates that a write of [count] registers at [address] for [unitId]
  /// is permitted. Throws [ModbusGuardException] if the guard rejects it or
  /// if [pipelineAuthorized] is `false`.
  void checkWrite({
    required int address,
    required int count,
    required int unitId,
    required bool pipelineAuthorized,
  }) {
    final allowed = guard.allows(
      function: ModbusFunction.writeMultipleRegisters,
      address: address,
      count: count,
      pipelineAuthorized: pipelineAuthorized,
    );
    if (!allowed) {
      throw ModbusGuardException(
        'Write of $count register(s) at $address (unit $unitId) rejected. '
        'Ensure writeVerifiedOnHardware and pipelineAuthorized are both true '
        'and the address is within allowed write ranges.',
      );
    }
  }

  // ── Async transport wrappers ─────────────────────────────────────────────

  /// Reads [count] holding registers starting at [address] from [unitId].
  ///
  /// Guard check runs synchronously before any I/O.
  Future<List<int>> readRegisters(
    int address,
    int count, {
    required int unitId,
  }) async {
    checkRead(address: address, count: count, unitId: unitId);
    if (transport == null) {
      return Future.delayed(
        timeout + const Duration(milliseconds: 1),
        () => throw const ModbusTimeout(),
      );
    }
    try {
      return await transport!(
        address: address,
        count: count,
        unitId: unitId,
        isWrite: false,
      ).timeout(timeout);
    } on TimeoutException {
      throw const ModbusTimeout();
    }
  }

  /// Writes [values] to registers starting at [address] on [unitId].
  ///
  /// Guard check (including [pipelineAuthorized]) runs synchronously first.
  Future<void> writeRegisters(
    int address,
    List<int> values, {
    required int unitId,
    required bool pipelineAuthorized,
  }) async {
    checkWrite(
      address: address,
      count: values.length,
      unitId: unitId,
      pipelineAuthorized: pipelineAuthorized,
    );
    if (transport == null) {
      return Future.delayed(
        timeout + const Duration(milliseconds: 1),
        () => throw const ModbusTimeout(),
      );
    }
    try {
      await transport!(
        address: address,
        count: values.length,
        unitId: unitId,
        isWrite: true,
        values: values,
      ).timeout(timeout);
    } on TimeoutException {
      throw const ModbusTimeout();
    }
  }
}

// Keep the standalone helper for callers that only need timeout wrapping.
Future<T> withModbusTimeout<T>(Future<T> response, Duration timeout) async {
  try {
    return await response.timeout(timeout);
  } on TimeoutException {
    throw const ModbusTimeout();
  }
}
