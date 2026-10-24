import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A1 gateway screen does not assert fixed guard state', () {
    final source = File('lib/features/gateway_screen.dart').readAsStringSync();

    expect(source, contains('session.gatewayStatus'));
    expect(RegExp(r's\.transmissionBlocked\b').hasMatch(source), isFalse);
    expect(RegExp(r's\.defaultMode\b').hasMatch(source), isFalse);
  });

  test('A4 feature screens contain no literal measurement-state claims', () {
    final forbidden = RegExp(
      r'''(?:Text|title|subtitle|label)\s*[:(]\s*['"](?:Healthy|ENFORCED|Verified|Online|Connected)\b''',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (forbidden.hasMatch(entity.readAsStringSync())) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);

    final link = File('lib/features/link_screen.dart').readAsStringSync();
    expect(link, isNot(contains('verdict.name')));
    expect(link, isNot(contains('finding.state.name')));
  });
}
