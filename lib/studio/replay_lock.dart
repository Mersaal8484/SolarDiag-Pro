import 'capture_models.dart';

class ReplayLock {
  const ReplayLock();
  Never transmitCapturedFrame(CaptureFrame frame) =>
      throw const ReplayProhibitedException();
  Never deriveHardwareTransmission(CaptureFrame frame) =>
      throw const ReplayProhibitedException();

  Future<Never> blockHardwareTransmission({
    required CaptureFrame frame,
    required Future<void> Function(List<int>) wireWriter,
  }) => Future<Never>.error(const ReplayProhibitedException());
}

class ReplayProhibitedException implements Exception {
  const ReplayProhibitedException();
  @override
  String toString() =>
      'Capture-derived frames can never be transmitted to hardware.';
}
