part of bullet.client.views;

@Component(
    selector: 'login-view',
    publishAs: 'ctrl',
    templateUrl: '/packages/bullet/client/views/login/login.html',
    cssUrl: const [
        '/packages/bullet/client/views/login/login.css',
        '/packages/bullet/client/views/views.css'])
class LoginView {

  static final ClientAuthenticator _FB = new FacebookClientAuthenticator();
  static final ClientAuthenticator _GOO = new GoogleClientAuthenticator();

  get FB => _FB;
  get GOO => _GOO;
  
  final ClientAuthenticatorProvider provider;
  final Router router;
  final EntityMapper<User> users;

  String query = '';

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
