part of bullet.client.authenticator_service;

class MockAuthenticationService implements AuthenticatiorClient {

  bool get isAuthenticated => true;

  /**
   * Attempts to authenticate.
   */
  Future authenticate() => new Future.value();
  
}
