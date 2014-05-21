library bullet.client.authenticator_service;

import 'dart:async';

abstract class AuthenticatorClient {
  String get token;
  bool get isInitialized;
  Future init();
  Future login();
  Future logout();
}
