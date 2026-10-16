import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/core/battery_models.dart';
import 'package:solardiag_pro/core/safe_write_pipeline.dart';

void main() {
  test('missing measurement never becomes zero', () {
    const value = Measurement.absent(DataAbsenceReason.notReported);
    expect(value.value, isNull);
    expect(value.isReported, isFalse);
  });
  test('writes require verified hardware and range', () {
    const pipeline = SafeWritePipeline();
    const request = WriteRequest(parameter: 'charge_limit', value: 55.2);
    expect(
      pipeline.canExecute(
        request,
        const WritePolicy(minimum: 48, maximum: 56, verifiedForHardware: false),
      ),
      isFalse,
    );
    expect(
      pipeline.canExecute(
        request,
        const WritePolicy(minimum: 48, maximum: 56, verifiedForHardware: true),
      ),
      isTrue,
    );
  });
  test(
    'raw writes are structurally blocked',
    () => expect(const SafeWritePipeline().directRawWrite, throwsStateError),
  );
}
