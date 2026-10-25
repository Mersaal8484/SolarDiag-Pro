import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/studio/can_signal_formats.dart';
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

  test('SLCAN importer preserves identifiers and reports malformed DLC', () {
    final result = const SlcanImporter().import(
      't351401020304\nT18FF50E52AABB0010\nt35130102',
      context,
    );
    expect(result.session!.source, CaptureSource.slcan);
    expect(result.session!.frames, hasLength(2));
    expect(result.session!.frames.first.identifier, 0x351);
    expect(result.session!.frames.last.extendedIdentifier, isTrue);
    expect(result.issues.single.line, 3);
  });

  test('Vector ASC importer keeps valid rows and line-numbered issues', () {
    const source = '''
date Sun Oct 25 23:00:00 2026
0.000100 1 351 Rx d 4 01 02 03 04
bad frame
0.000200 2 18FF50E5x Tx d 2 AA BB
''';
    final result = const VectorAscImporter().import(source, context);
    expect(result.session!.source, CaptureSource.vectorAsc);
    expect(result.session!.frames, hasLength(2));
    expect(result.session!.frames.last.extendedIdentifier, isTrue);
    expect(result.issues.single.line, 3);
  });

  test('PEAK TRC importer does not repair malformed payloads', () {
    const source =
        r'''
;$FILEVERSION=1.1
1) 0.100 Rx 0351 4 01 02 03 04
2) 0.200 Tx 0352 3 AA BB
''';
    final result = const PeakTrcImporter().import(source, context);
    expect(result.session!.source, CaptureSource.peakTrc);
    expect(result.session!.frames.single.identifier, 0x351);
    expect(result.issues.single.line, 3);
  });

  test('DBC import and export preserve CAN signal semantics', () {
    const source = '''
VERSION "fixture"
BO_ 849 Battery: 8 Vector__XXX
 SG_ PackVoltage : 0|16@1+ (0.1,0) [0|100] "V" Vector__XXX
 SG_ Broken : bad
''';
    const codec = DbcSignalCodec();
    final decoded = codec.decode(source);
    expect(decoded.signals.single.name, 'PackVoltage');
    expect(decoded.signals.single.messageId, 849);
    expect(decoded.signals.single.littleEndian, isTrue);
    expect(decoded.issues.single.line, 4);
    final restored = codec.decode(codec.encode(decoded.signals));
    expect(restored.hasErrors, isFalse);
    expect(restored.signals.single.scale, .1);
  });

  test('KCD import and export preserve CAN signal semantics', () {
    const source = '''
<NetworkDefinition>
  <Bus name="fixture">
    <Message id="0x351" name="Battery">
      <Signal name="PackVoltage" offset="0" length="16" endianess="little" signed="false" factor="0.1" intercept="0" unit="V" />
      <Signal name="Broken" offset="bad" length="16" />
    </Message>
  </Bus>
</NetworkDefinition>
''';
    const codec = KcdSignalCodec();
    final decoded = codec.decode(source);
    expect(decoded.signals.single.messageId, 0x351);
    expect(decoded.signals.single.name, 'PackVoltage');
    expect(decoded.issues.single.line, 5);
    final restored = codec.decode(codec.encode(decoded.signals));
    expect(restored.hasErrors, isFalse);
    expect(restored.signals.single.unit, 'V');
  });

  test('unimplemented formats are explicitly listed as unsupported', () {
    expect(CaptureImporterRegistry.unsupportedFormats, [
      'pcap Modbus TCP',
      'pcapng Modbus TCP',
      'serial-sniffer binary logs',
      'serial-monitor vendor exports',
    ]);
  });
}
