import 'dart:async';
import 'package:flutter/foundation.dart';
import '../parameters/parameter_models.dart';

abstract interface class TechnicianAuthenticator {
  Future<bool> authenticate({
    required AuthorizationTier tier,
    required String credentials,
  });
}

/// Fail-closed default authenticator. Always rejects authentication attempts.
class NoAuthenticator implements TechnicianAuthenticator {
  const NoAuthenticator();

  @override
  Future<bool> authenticate({
    required AuthorizationTier tier,
    required String credentials,
  }) async => false;
}

/// Configuration injected into app and test sessions.
/// In production, [isDemoMode] is false and authentication fails closed unless
/// an external authentication provider is configured.
class DemoConfiguration {
  /// A demo authenticator is never enabled implicitly.  The credential is
  /// supplied only by the demo/test harness and is deliberately not shipped
  /// as a literal application secret.
  const DemoConfiguration({this.isDemoMode = false, required this.demoPin});

  final bool isDemoMode;
  final String demoPin;

  TechnicianAuthenticator createAuthenticator() {
    if (!isDemoMode) return const NoAuthenticator();
    return MockTechnicianAuthenticator(demoPin: demoPin);
  }
}

class MockTechnicianAuthenticator implements TechnicianAuthenticator {
  const MockTechnicianAuthenticator({
    this.acceptAll = false,
    required this.demoPin,
  });
  final bool acceptAll;
  final String demoPin;

  @override
  Future<bool> authenticate({
    required AuthorizationTier tier,
    required String credentials,
  }) async {
    if (acceptAll) return true;
    return credentials == demoPin;
  }
}

sealed class AuthorizationState {
  const AuthorizationState();
  bool get isUnlocked => this is UnlockedAuthorizationState;
  AuthorizationSession? get session => switch (this) {
    UnlockedAuthorizationState(:final session) => session,
    _ => null,
  };
}

final class LockedAuthorizationState extends AuthorizationState {
  const LockedAuthorizationState([this.reason]);
  final String? reason;
}

final class UnlockedAuthorizationState extends AuthorizationState {
  const UnlockedAuthorizationState(this._authSession);
  final AuthorizationSession _authSession;
  @override
  AuthorizationSession? get session => _authSession;
}

class AuthorizationController extends ChangeNotifier {
  AuthorizationController({
    TechnicianAuthenticator? authenticator,
    DateTime Function()? clock,
  }) : _authenticator = authenticator ?? const NoAuthenticator(),
       _clock = clock ?? DateTime.now;

  final TechnicianAuthenticator _authenticator;
  final DateTime Function() _clock;
  AuthorizationState _state = const LockedAuthorizationState();

  AuthorizationState get state => _checkExpiry();
  bool get isUnlocked => state.isUnlocked;
  AuthorizationSession? get current => state.session;

  AuthorizationState _checkExpiry() {
    if (_state is UnlockedAuthorizationState) {
      final unlocked = _state as UnlockedAuthorizationState;
      if (unlocked.session?.isExpiredAt(_clock()) ?? false) {
        _state = const LockedAuthorizationState('Session expired');
        notifyListeners();
      }
    }
    return _state;
  }

  Future<bool> unlock({
    required AuthorizationTier tier,
    required String credentials,
    Duration duration = const Duration(minutes: 15),
  }) async {
    final ok = await _authenticator.authenticate(
      tier: tier,
      credentials: credentials,
    );
    if (!ok) {
      _state = const LockedAuthorizationState('Authentication failed');
      notifyListeners();
      return false;
    }
    final now = _clock().toUtc();
    _state = UnlockedAuthorizationState(
      AuthorizationSession(tier: tier, expiresAt: now.add(duration)),
    );
    notifyListeners();
    return true;
  }

  void lock([String? reason]) {
    if (_state is! LockedAuthorizationState) {
      _state = LockedAuthorizationState(reason);
      notifyListeners();
    }
  }
}
