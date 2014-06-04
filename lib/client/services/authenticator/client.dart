library bullet.authenticator.client;

import 'dart:async';
import 'package:angular/angular.dart';
import 'package:bullet/shared/authenticator/authenticator.dart';
import 'package:bullet/client/services/database/entities.dart';

abstract class ClientAuthenticator extends Authenticator {
  bool get isInitialized;
  Future init();
  Future login();
  Future logout();
}

/**
 * Captures the state of the current authenticator.
 */
@Injectable()
class ClientAuthenticatorProvider {
  ClientAuthenticator auth;
  bool get isLoggedIn => auth != null && !auth.hasExpired;
}