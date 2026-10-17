import 'capture_models.dart';

class ReplayLock {
  const ReplayLock();
  Never transmitCapturedFrame(CaptureFrame frame) =>
      throw const ReplayProhibitedException();
  Never deriveHardwareTransmission(CaptureFrame frame) =>
      throw const ReplayProhibitedException();
}

class ReplayProhibitedException implements Exception {
  const ReplayProhibitedException();
  @override
  String toString() =>
      'Capture-derived frames can never be transmitted to hardware.';
}
