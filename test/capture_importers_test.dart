import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/capture_importers.dart';
import 'package:solardiag_pro/studio/capture_models.dart';

void main() {
  final context = CaptureImportContext(
    sessionId: 'imported-1',
    startedAt: DateTime.utc(2026),
    synthetic: true,
    containsNdaMaterial: false,
    notes: 'import test',
  );

  test(
    'candump importer keeps valid frames and reports malformed line number',
    () {
      const source = '''
(1.000001) can0 351#01020304
malformed line
(1.100001) can1 18FF50E5 [2] AA BB
''';
      final result = const CandumpImporter().import(source, context);
      expect(result.session!.frames, hasLength(2));
      expect(result.session!.frames.first.timestampNanos, 1000001000);
      expect(result.session!.frames.last.extendedIdentifier, isTrue);
      expect(result.issues.single.line, 2);
      expect(result.hasErrors, isTrue);
    },
  );

  test('CSV mapping assistant and importer preserve mapped direction', () {
    const assistant = CsvMappingAssistant();
    final mapping = assistant.suggest('timestamp_us,can_id,data,dir,channel')!;
    final result = CsvCaptureImporter(mapping).import(
      'timestamp_us,can_id,data,dir,channel\n100,351,01 02,RX,bus-a',
      context,
    );
    final frame = result.session!.frames.single;
    expect(frame.timestampNanos, 100000);
    expect(frame.identifier, 0x351);
    expect(frame.direction, CaptureDirection.rx);
    expect(frame.channel, 'bus-a');
  });

  test('CSV importer never silently fixes malformed rows', () {
    const mapping = CsvColumnMapping(timestamp: 'time', payload: 'data');
    final result = const CsvCaptureImporter(
      mapping,
    ).import('time,data\n1,0102\n2,0GG2\n3,01,extra', context);
    expect(result.session!.frames, hasLength(1));
    expect(result.issues.map((issue) => issue.line), [3, 4]);
  });

  test('generic hex importer applies explicit rules and reports bad bytes', () {
    const importer = GenericHexImporter(
      GenericHexRules(
        delimiter: '|',
        timestampColumn: 0,
        directionColumn: 1,
        payloadStartColumn: 2,
        timestampUnit: 'ns',
      ),
    );
    final result = importer.import('10|TX|01 03 00\n20|RX|invalid', context);
    expect(result.session!.frames.single.direction, CaptureDirection.tx);
    expect(result.session!.frames.single.rawBytes, [1, 3, 0]);
    expect(result.issues.single.line, 2);
  });

  test('unimplemented formats are explicitly listed as unsupported', () {
    expect(CaptureImporterRegistry.unsupportedFormats, [
      'SLCAN',
      'pcap/pcapng Modbus TCP',
      'Vector ASC',
    ]);
  });
}
