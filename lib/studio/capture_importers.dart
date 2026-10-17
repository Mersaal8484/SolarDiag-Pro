import 'dart:convert';

import 'capture_models.dart';
import 'sdcap_codec.dart';

enum ImportIssueSeverity { warning, error }

class CaptureImportIssue {
  const CaptureImportIssue({
    required this.line,
    required this.message,
    required this.severity,
  });
  final int line;
  final String message;
  final ImportIssueSeverity severity;
}

class CaptureImportContext {
  const CaptureImportContext({
    required this.sessionId,
    required this.startedAt,
    required this.synthetic,
    required this.containsNdaMaterial,
    this.notes = '',
  });
  final String sessionId;
  final DateTime startedAt;
  final bool synthetic;
  final bool containsNdaMaterial;
  final String notes;
}

class CaptureImportResult {
  const CaptureImportResult({
    required this.session,
    required this.issues,
    this.unsupportedFormats = const [],
  });
  final CaptureSession? session;
  final List<CaptureImportIssue> issues;
  final List<String> unsupportedFormats;
  bool get hasErrors =>
      issues.any((issue) => issue.severity == ImportIssueSeverity.error);
}

abstract interface class CaptureImporter {
  String get formatName;
  bool supportsFileName(String fileName);
  CaptureImportResult import(String source, CaptureImportContext context);
}

class SdcapImporter implements CaptureImporter {
  const SdcapImporter({this.codec = const SdcapCodec()});
  final SdcapCodec codec;
  @override
  String get formatName => 'SolarDiag Capture';
  @override
  bool supportsFileName(String fileName) =>
      fileName.toLowerCase().endsWith('.sdcap');
  @override
  CaptureImportResult import(String source, CaptureImportContext context) {
    try {
      return CaptureImportResult(
        session: codec.decode(source).session,
        issues: const [],
      );
    } on FormatException catch (error) {
      return CaptureImportResult(
        session: null,
        issues: [
          CaptureImportIssue(
            line: 1,
            message: error.message.toString(),
            severity: ImportIssueSeverity.error,
          ),
        ],
      );
    }
  }
}

class CandumpImporter implements CaptureImporter {
  const CandumpImporter();
  @override
  String get formatName => 'Linux candump';
  @override
  bool supportsFileName(String fileName) =>
      fileName.toLowerCase().endsWith('.log') ||
      fileName.toLowerCase().endsWith('.candump');

  @override
  CaptureImportResult import(String source, CaptureImportContext context) {
    final frames = <CapturedFrame>[];
    final issues = <CaptureImportIssue>[];
    final lines = const LineSplitter().convert(source);
    final compact = RegExp(
      r'^\s*(?:\((\d+(?:\.\d+)?)\)\s+)?(\S+)\s+([0-9A-Fa-f]{1,8})#([0-9A-Fa-f]*)\s*$',
    );
    final spaced = RegExp(
      r'^\s*(?:\((\d+(?:\.\d+)?)\)\s+)?(\S+)\s+([0-9A-Fa-f]{1,8})\s+\[(\d+)\]\s*((?:[0-9A-Fa-f]{2}\s*)*)$',
    );
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        continue;
      }
      final compactMatch = compact.firstMatch(line);
      final spacedMatch = spaced.firstMatch(line);
      if (compactMatch == null && spacedMatch == null) {
        issues.add(_lineError(index, 'Malformed candump line.'));
        continue;
      }
      final timestamp = (compactMatch ?? spacedMatch)!.group(1);
      final channel = (compactMatch ?? spacedMatch)!.group(2)!;
      final identifierText = (compactMatch ?? spacedMatch)!.group(3)!;
      final bytesText = compactMatch != null
          ? compactMatch.group(4)!
          : spacedMatch!.group(5)!.replaceAll(RegExp(r'\s+'), '');
      if (bytesText.length.isOdd) {
        issues.add(
          _lineError(index, 'Hex payload has an odd number of digits.'),
        );
        continue;
      }
      final declaredLength = spacedMatch == null
          ? bytesText.length ~/ 2
          : int.parse(spacedMatch.group(4)!);
      if (declaredLength != bytesText.length ~/ 2) {
        issues.add(
          _lineError(index, 'Declared length does not match payload.'),
        );
        continue;
      }
      frames.add(
        CapturedFrame(
          timestampNanos: timestamp == null
              ? index * 1000000
              : (double.parse(timestamp) * 1000000000).round(),
          rawBytes: _decodeHex(bytesText),
          direction: CaptureDirection.unknown,
          channel: channel,
          identifier: int.parse(identifierText, radix: 16),
          extendedIdentifier: identifierText.length > 3,
          protocolHint: 'CAN',
        ),
      );
    }
    return CaptureImportResult(
      session: _session(
        context,
        CaptureInterface.can,
        CaptureSource.candump,
        frames,
      ),
      issues: List.unmodifiable(issues),
    );
  }
}

class CsvColumnMapping {
  const CsvColumnMapping({
    required this.timestamp,
    required this.payload,
    this.identifier,
    this.direction,
    this.channel,
    this.timestampUnit = 'us',
    this.delimiter = ',',
  });
  final String timestamp;
  final String payload;
  final String? identifier;
  final String? direction;
  final String? channel;
  final String timestampUnit;
  final String delimiter;
}

class CsvMappingAssistant {
  const CsvMappingAssistant();
  CsvColumnMapping? suggest(String headerLine, {String delimiter = ','}) {
    final headers = headerLine
        .split(delimiter)
        .map((item) => item.trim())
        .toList();
    String? find(List<String> candidates) {
      for (final header in headers) {
        if (candidates.contains(header.toLowerCase())) {
          return header;
        }
      }
      return null;
    }

    final timestamp = find([
      'timestamp',
      'time',
      'timestamp_us',
      'timestamp_ns',
    ]);
    final payload = find(['payload', 'data', 'bytes', 'hex']);
    if (timestamp == null || payload == null) {
      return null;
    }
    return CsvColumnMapping(
      timestamp: timestamp,
      payload: payload,
      identifier: find(['identifier', 'id', 'can_id']),
      direction: find(['direction', 'dir']),
      channel: find(['channel', 'interface']),
      timestampUnit: timestamp.toLowerCase().endsWith('_ns') ? 'ns' : 'us',
      delimiter: delimiter,
    );
  }
}

class CsvCaptureImporter implements CaptureImporter {
  const CsvCaptureImporter(this.mapping);
  final CsvColumnMapping mapping;
  @override
  String get formatName => 'Mapped CSV';
  @override
  bool supportsFileName(String fileName) =>
      fileName.toLowerCase().endsWith('.csv');

  @override
  CaptureImportResult import(String source, CaptureImportContext context) {
    final lines = const LineSplitter().convert(source);
    if (lines.isEmpty) {
      return CaptureImportResult(
        session: null,
        issues: [_lineError(0, 'CSV file is empty.')],
      );
    }
    final headers = lines.first
        .split(mapping.delimiter)
        .map((item) => item.trim())
        .toList();
    int column(String name) => headers.indexOf(name);
    final timestampColumn = column(mapping.timestamp);
    final payloadColumn = column(mapping.payload);
    if (timestampColumn < 0 || payloadColumn < 0) {
      return CaptureImportResult(
        session: null,
        issues: [_lineError(0, 'Mapped CSV columns are missing.')],
      );
    }
    final frames = <CapturedFrame>[];
    final issues = <CaptureImportIssue>[];
    for (var index = 1; index < lines.length; index++) {
      if (lines[index].trim().isEmpty) {
        continue;
      }
      final values = lines[index].split(mapping.delimiter);
      if (values.length != headers.length) {
        issues.add(
          _lineError(index, 'CSV column count does not match header.'),
        );
        continue;
      }
      final timestamp = num.tryParse(values[timestampColumn].trim());
      final bytes = _tryDecodeHex(values[payloadColumn]);
      if (timestamp == null || bytes == null) {
        issues.add(_lineError(index, 'Invalid timestamp or hex payload.'));
        continue;
      }
      final identifier = mapping.identifier == null
          ? null
          : int.tryParse(
              values[column(mapping.identifier!)].trim().replaceFirst('0x', ''),
              radix: 16,
            );
      frames.add(
        CapturedFrame(
          timestampNanos: mapping.timestampUnit == 'ns'
              ? timestamp.round()
              : (timestamp * 1000).round(),
          rawBytes: bytes,
          direction: _direction(
            mapping.direction == null
                ? null
                : values[column(mapping.direction!)],
          ),
          channel: mapping.channel == null
              ? 'csv'
              : values[column(mapping.channel!)].trim(),
          identifier: identifier,
          extendedIdentifier: identifier != null && identifier > 0x7ff,
          protocolHint: identifier == null ? null : 'CAN',
        ),
      );
    }
    return CaptureImportResult(
      session: _session(
        context,
        frames.any((frame) => frame.identifier != null)
            ? CaptureInterface.can
            : CaptureInterface.imported,
        CaptureSource.csv,
        frames,
      ),
      issues: List.unmodifiable(issues),
    );
  }
}

class GenericHexRules {
  const GenericHexRules({
    this.delimiter = ' ',
    this.timestampColumn = 0,
    this.payloadStartColumn = 1,
    this.timestampUnit = 'us',
    this.directionColumn,
    this.channel = 'text',
  });
  final String delimiter;
  final int timestampColumn;
  final int payloadStartColumn;
  final String timestampUnit;
  final int? directionColumn;
  final String channel;
}

class GenericHexImporter implements CaptureImporter {
  const GenericHexImporter(this.rules);
  final GenericHexRules rules;
  @override
  String get formatName => 'Generic hex/text';
  @override
  bool supportsFileName(String fileName) => true;
  @override
  CaptureImportResult import(String source, CaptureImportContext context) {
    final frames = <CapturedFrame>[];
    final issues = <CaptureImportIssue>[];
    final lines = const LineSplitter().convert(source);
    for (var index = 0; index < lines.length; index++) {
      if (lines[index].trim().isEmpty) {
        continue;
      }
      final columns = lines[index]
          .trim()
          .split(rules.delimiter)
          .where((item) => item.isNotEmpty)
          .toList();
      if (rules.timestampColumn >= columns.length ||
          rules.payloadStartColumn >= columns.length) {
        issues.add(_lineError(index, 'Configured columns are missing.'));
        continue;
      }
      final timestamp = num.tryParse(columns[rules.timestampColumn]);
      final payloadColumns = columns.sublist(rules.payloadStartColumn);
      final bytes = _tryDecodeHex(payloadColumns.join());
      if (timestamp == null || bytes == null) {
        issues.add(_lineError(index, 'Invalid timestamp or hex bytes.'));
        continue;
      }
      frames.add(
        CapturedFrame(
          timestampNanos: rules.timestampUnit == 'ns'
              ? timestamp.round()
              : (timestamp * 1000).round(),
          rawBytes: bytes,
          direction:
              rules.directionColumn == null ||
                  rules.directionColumn! >= columns.length
              ? CaptureDirection.unknown
              : _direction(columns[rules.directionColumn!]),
          channel: rules.channel,
        ),
      );
    }
    return CaptureImportResult(
      session: _session(
        context,
        CaptureInterface.imported,
        CaptureSource.genericText,
        frames,
      ),
      issues: List.unmodifiable(issues),
    );
  }
}

class CaptureImporterRegistry {
  const CaptureImporterRegistry();
  static const unsupportedFormats = [
    'SLCAN',
    'pcap/pcapng Modbus TCP',
    'Vector ASC',
  ];
  List<CaptureImporter> defaults({CsvColumnMapping? csvMapping}) => [
    const SdcapImporter(),
    const CandumpImporter(),
    if (csvMapping != null) CsvCaptureImporter(csvMapping),
  ];
}

CaptureSession _session(
  CaptureImportContext context,
  CaptureInterface interfaceType,
  CaptureSource source,
  List<CapturedFrame> frames,
) => CaptureSession(
  id: context.sessionId,
  interfaceType: interfaceType,
  source: source,
  startedAt: context.startedAt,
  frames: List.unmodifiable(frames),
  synthetic: context.synthetic,
  containsNdaMaterial: context.containsNdaMaterial,
  notes: context.notes,
  clockSource: 'imported',
);

CaptureImportIssue _lineError(int zeroBasedLine, String message) =>
    CaptureImportIssue(
      line: zeroBasedLine + 1,
      message: message,
      severity: ImportIssueSeverity.error,
    );

List<int> _decodeHex(String source) => [
  for (var index = 0; index < source.length; index += 2)
    int.parse(source.substring(index, index + 2), radix: 16),
];

List<int>? _tryDecodeHex(String source) {
  final compact = source.replaceAll(RegExp(r'[\s:_-]'), '');
  if (compact.isEmpty ||
      compact.length.isOdd ||
      !RegExp(r'^[0-9a-fA-F]+$').hasMatch(compact)) {
    return null;
  }
  return _decodeHex(compact);
}

CaptureDirection _direction(String? value) =>
    switch (value?.trim().toLowerCase()) {
      'rx' || 'r' || 'receive' => CaptureDirection.rx,
      'tx' || 't' || 'transmit' => CaptureDirection.tx,
      _ => CaptureDirection.unknown,
    };
