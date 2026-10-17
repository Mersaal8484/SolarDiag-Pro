import 'dart:convert';

import '../persistence/local_database.dart';
import 'capture_models.dart';
import 'findings.dart';
import 'sdcap_codec.dart';

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

class LocalResearchRepository implements ResearchRepository {
  const LocalResearchRepository(
    this.database, {
    this.codec = const SdcapCodec(),
  });

  final LocalDatabase database;
  final SdcapCodec codec;

  @override
  Future<void> saveSession(CaptureSession session) async {
    database.saveResearchSessionDocument(
      session.id,
      codec.encode(session, forLocalStorage: true),
    );
  }

  @override
  Future<void> saveFinding(ProtocolFinding finding) async {
    database.saveResearchFindingDocument(
      finding.id,
      jsonEncode(finding.toJson()),
    );
  }

  @override
  Future<CaptureSession?> session(String id) async {
    final document = database.researchSessionDocument(id);
    return document == null ? null : codec.decode(document).session;
  }

  @override
  Future<List<ProtocolFinding>> findings() async => [
    for (final document in database.researchFindingDocuments())
      ProtocolFinding.fromJson(jsonDecode(document) as Map<String, Object?>),
  ];
}
