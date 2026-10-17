import 'capture_models.dart';
import 'findings.dart';

abstract interface class ResearchRepository {
  Future<void> saveSession(CaptureSession session);
  Future<void> saveFinding(ProtocolFinding finding);
  Future<CaptureSession?> session(String id);
  Future<List<ProtocolFinding>> findings();
}

class InMemoryResearchRepository implements ResearchRepository {
  final Map<String, CaptureSession> _sessions = {};
  final Map<String, ProtocolFinding> _findings = {};
  @override
  Future<void> saveSession(CaptureSession session) async =>
      _sessions[session.id] = session;
  @override
  Future<void> saveFinding(ProtocolFinding finding) async =>
      _findings[finding.id] = finding;
  @override
  Future<CaptureSession?> session(String id) async => _sessions[id];
  @override
  Future<List<ProtocolFinding>> findings() async =>
      List.unmodifiable(_findings.values);
}
