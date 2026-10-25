import 'dart:convert';

class CanSignalDefinition {
  const CanSignalDefinition({
    required this.messageId,
    required this.messageName,
    required this.name,
    required this.startBit,
    required this.length,
    required this.littleEndian,
    required this.signed,
    required this.scale,
    required this.offset,
    required this.unit,
  });

  final int messageId;
  final String messageName;
  final String name;
  final int startBit;
  final int length;
  final bool littleEndian;
  final bool signed;
  final double scale;
  final double offset;
  final String unit;
}

class CanSignalFormatIssue {
  const CanSignalFormatIssue({required this.line, required this.message});

  final int line;
  final String message;
}

class CanSignalImportResult {
  const CanSignalImportResult({required this.signals, required this.issues});

  final List<CanSignalDefinition> signals;
  final List<CanSignalFormatIssue> issues;

  bool get hasErrors => issues.isNotEmpty;
}

class DbcSignalCodec {
  const DbcSignalCodec();

  CanSignalImportResult decode(String source) {
    final signals = <CanSignalDefinition>[];
    final issues = <CanSignalFormatIssue>[];
    final lines = const LineSplitter().convert(source);
    final messagePattern = RegExp(
      r'^\s*BO_\s+(\d+)\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(\d+)\s+\S+',
    );
    final signalPattern = RegExp(
      r'^\s*SG_\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(\d+)\|(\d+)@([01])([+-])\s+\(([-+0-9.eE]+),([-+0-9.eE]+)\)\s+\[[^\]]*\]\s+"([^"]*)"',
    );
    int? messageId;
    String? messageName;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('VERSION') ||
          trimmed.startsWith('NS_') ||
          trimmed.startsWith('BS_') ||
          trimmed.startsWith('BU_') ||
          trimmed.startsWith('CM_')) {
        continue;
      }
      final message = messagePattern.firstMatch(line);
      if (message != null) {
        messageId = int.parse(message.group(1)!);
        messageName = message.group(2)!;
        continue;
      }
      if (trimmed.startsWith('BO_')) {
        issues.add(_issue(index, 'Malformed DBC message declaration.'));
        messageId = null;
        messageName = null;
        continue;
      }
      if (!trimmed.startsWith('SG_')) {
        continue;
      }
      final signal = signalPattern.firstMatch(line);
      if (signal == null || messageId == null || messageName == null) {
        issues.add(
          _issue(index, 'Malformed DBC signal or signal without a message.'),
        );
        continue;
      }
      final definition = CanSignalDefinition(
        messageId: messageId,
        messageName: messageName,
        name: signal.group(1)!,
        startBit: int.parse(signal.group(2)!),
        length: int.parse(signal.group(3)!),
        littleEndian: signal.group(4) == '1',
        signed: signal.group(5) == '-',
        scale: double.parse(signal.group(6)!),
        offset: double.parse(signal.group(7)!),
        unit: signal.group(8)!,
      );
      if (!_validSignal(definition)) {
        issues.add(_issue(index, 'DBC signal range is invalid.'));
        continue;
      }
      signals.add(definition);
    }
    return CanSignalImportResult(
      signals: List.unmodifiable(signals),
      issues: List.unmodifiable(issues),
    );
  }

  String encode(Iterable<CanSignalDefinition> signals) {
    final ordered = signals.toList()
      ..sort((a, b) {
        final messageOrder = a.messageId.compareTo(b.messageId);
        return messageOrder != 0
            ? messageOrder
            : a.startBit.compareTo(b.startBit);
      });
    final grouped = <int, List<CanSignalDefinition>>{};
    for (final signal in ordered) {
      if (!_validSignal(signal)) {
        throw const FormatException('Cannot export an invalid CAN signal.');
      }
      (grouped[signal.messageId] ??= []).add(signal);
    }
    final buffer = StringBuffer('VERSION "SolarDiag Studio"\n\n');
    for (final entry in grouped.entries) {
      final message = entry.value.first;
      final maximumBit = entry.value
          .map((signal) => signal.startBit + signal.length)
          .reduce((a, b) => a > b ? a : b);
      final dlc = ((maximumBit + 7) ~/ 8).clamp(1, 64);
      buffer.writeln('BO_ ${entry.key} ${message.messageName}: $dlc SolarDiag');
      for (final signal in entry.value) {
        final byteOrder = signal.littleEndian ? 1 : 0;
        final sign = signal.signed ? '-' : '+';
        buffer.writeln(
          ' SG_ ${signal.name} : ${signal.startBit}|${signal.length}'
          '@$byteOrder$sign (${signal.scale},${signal.offset}) '
          '[0|0] "${signal.unit}" Vector__XXX',
        );
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}

class KcdSignalCodec {
  const KcdSignalCodec();

  CanSignalImportResult decode(String source) {
    final signals = <CanSignalDefinition>[];
    final issues = <CanSignalFormatIssue>[];
    final lines = const LineSplitter().convert(source);
    int? messageId;
    String? messageName;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty || line.startsWith('<?') || line.startsWith('<!--')) {
        continue;
      }
      if (line.startsWith('<Message ')) {
        final attributes = _attributes(line);
        messageId = _parseFlexibleInt(attributes['id']);
        messageName = attributes['name'];
        if (messageId == null || messageName == null || messageName.isEmpty) {
          issues.add(_issue(index, 'Malformed KCD Message element.'));
          messageId = null;
          messageName = null;
        }
        continue;
      }
      if (!line.startsWith('<Signal ')) {
        continue;
      }
      final attributes = _attributes(line);
      final startBit = int.tryParse(attributes['offset'] ?? '');
      final length = int.tryParse(attributes['length'] ?? '');
      final scale = double.tryParse(attributes['factor'] ?? '1');
      final offset = double.tryParse(attributes['intercept'] ?? '0');
      final name = attributes['name'];
      if (messageId == null ||
          messageName == null ||
          name == null ||
          startBit == null ||
          length == null ||
          scale == null ||
          offset == null) {
        issues.add(_issue(index, 'Malformed KCD Signal element.'));
        continue;
      }
      final definition = CanSignalDefinition(
        messageId: messageId,
        messageName: messageName,
        name: name,
        startBit: startBit,
        length: length,
        littleEndian: attributes['endianess'] != 'big',
        signed: attributes['signed'] == 'true',
        scale: scale,
        offset: offset,
        unit: attributes['unit'] ?? '',
      );
      if (!_validSignal(definition)) {
        issues.add(_issue(index, 'KCD signal range is invalid.'));
        continue;
      }
      signals.add(definition);
    }
    return CanSignalImportResult(
      signals: List.unmodifiable(signals),
      issues: List.unmodifiable(issues),
    );
  }

  String encode(Iterable<CanSignalDefinition> signals) {
    final ordered = signals.toList()
      ..sort((a, b) {
        final messageOrder = a.messageId.compareTo(b.messageId);
        return messageOrder != 0
            ? messageOrder
            : a.startBit.compareTo(b.startBit);
      });
    final grouped = <int, List<CanSignalDefinition>>{};
    for (final signal in ordered) {
      if (!_validSignal(signal)) {
        throw const FormatException('Cannot export an invalid CAN signal.');
      }
      (grouped[signal.messageId] ??= []).add(signal);
    }
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<NetworkDefinition>\n  <Bus name="SolarDiag">\n',
    );
    for (final entry in grouped.entries) {
      buffer.writeln(
        '    <Message id="0x${entry.key.toRadixString(16).toUpperCase()}" '
        'name="${_xml(entry.value.first.messageName)}">',
      );
      for (final signal in entry.value) {
        buffer.writeln(
          '      <Signal name="${_xml(signal.name)}" '
          'offset="${signal.startBit}" length="${signal.length}" '
          'endianess="${signal.littleEndian ? 'little' : 'big'}" '
          'signed="${signal.signed}" factor="${signal.scale}" '
          'intercept="${signal.offset}" unit="${_xml(signal.unit)}" />',
        );
      }
      buffer.writeln('    </Message>');
    }
    buffer.write('  </Bus>\n</NetworkDefinition>\n');
    return buffer.toString();
  }
}

CanSignalFormatIssue _issue(int zeroBasedLine, String message) =>
    CanSignalFormatIssue(line: zeroBasedLine + 1, message: message);

bool _validSignal(CanSignalDefinition signal) =>
    signal.startBit >= 0 &&
    signal.length > 0 &&
    signal.length <= 64 &&
    signal.startBit + signal.length <= 512 &&
    signal.scale.isFinite &&
    signal.offset.isFinite;

Map<String, String> _attributes(String element) => {
  for (final match in RegExp(r'(\w+)="([^"]*)"').allMatches(element))
    match.group(1)!: match.group(2)!,
};

int? _parseFlexibleInt(String? source) {
  if (source == null) {
    return null;
  }
  return source.toLowerCase().startsWith('0x')
      ? int.tryParse(source.substring(2), radix: 16)
      : int.tryParse(source);
}

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
