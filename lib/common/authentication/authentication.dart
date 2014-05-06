library bullet.client.authenticator_service;

import 'dart:async';
import 'package:di/di.dart';
import 'package:bullet/common/connector/connector.dart';

part 'impl/facebook_authentication.dart';
part 'impl/google_authentication.dart';
part 'impl/mock_authentication.dart';


/**
 * A service that uses an [AuthenticationConfiguration] to authenticate against a service.
 */
abstract class AuthenticationService {

  bool get isAuthenticated;

  /**
   * Attempts to authenticate.
   */
  Future authenticate();

}

class AuthenticationModule extends Module {
  AuthenticationModule() {
    bind(FacebookAuthenticationService);
    bind(GoogleAuthenticationService);
    bind(MockAuthenticationService);
  }
}
