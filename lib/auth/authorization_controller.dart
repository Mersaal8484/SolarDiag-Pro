import 'dart:async';
import 'package:flutter/foundation.dart';
import '../parameters/parameter_models.dart';

abstract interface class TechnicianAuthenticator {
  Future<bool> authenticate({
    required AuthorizationTier tier,
    required String credentials,
  });
}

class MockTechnicianAuthenticator implements TechnicianAuthenticator {
  const MockTechnicianAuthenticator({this.acceptAll = true});
  final bool acceptAll;

  @override
  Future<bool> authenticate({
    required AuthorizationTier tier,
    required String credentials,
  }) async => acceptAll;
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
  const UnlockedAuthorizationState(this.session);
  final AuthorizationSession session;
}

class AuthorizationController extends ChangeNotifier {
  AuthorizationController({
    TechnicianAuthenticator? authenticator,
    DateTime Function()? clock,
  }) : _authenticator = authenticator ?? const MockTechnicianAuthenticator(),
       _clock = clock ?? DateTime.now;

  final TechnicianAuthenticator _authenticator;
  final DateTime Function() _clock;
  AuthorizationState _state = const LockedAuthorizationState();

  AuthorizationState get state => _checkExpiry();
  bool get isUnlocked => state.isUnlocked;
  AuthorizationSession? get current => state.session;

  AuthorizationState _checkExpiry() {
    if (_state is UnlockedAuthorizationState) {
      final session = (_state as UnlockedAuthorizationState).session;
      if (session.isExpiredAt(_clock())) {
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
      AuthorizationSession(
        tier: tier,
        expiresAt: now.add(duration),
      ),
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
