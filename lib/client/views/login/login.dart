part of bullet.client.views;

@Component(
    selector: 'login-view',
    publishAs: 'ctrl',
    templateUrl: '/packages/bullet/client/views/login/login.html',
    cssUrl: const [
        '/packages/bullet/client/views/login/login.css',
        '/packages/bullet/client/views/views.css'])
class LoginView {

  static ClientAuthenticator _FB, _GOO;

  final ClientAuthenticatorProvider provider;
  final Router router;
  final UserMapper users;

  String query = '';

  ClientAuthenticator get FB => (_FB == null) ? _FB = new FacebookClientAuthenticator() : _FB;
  ClientAuthenticator get GOO => (_GOO == null) ? _GOO = new GoogleClientAuthenticator() : _GOO;

  bool isLoading = true;

  LoginView(this.provider, this.router, this.users) {
    Future.wait([FB.init(), GOO.init()]).then((_) => isLoading = false);
  }

  Future _login(ClientAuthenticator authenticator) {
    if (authenticator.isInitialized) {
      return authenticator.login()
        .then((_) => provider.auth = authenticator)
        .then((_) => router.go('profile', { 'userId': 'me' }))
        .catchError((_) => null);
    }
  }

  Future fbLogin() => _login(FB);
  Future gooLogin() => _login(GOO);
}
