part of bullet.client.views;

@Component(
  selector: 'login-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/login/login.html',
  cssUrl: '/packages/bullet/client/views/login/login.css')
class LoginView {
  String query = '';

  final ClientAuthenticator FB = new FacebookClientAuthenticator();
  final ClientAuthenticator GOO = new GoogleClientAuthenticator();

  final ClientAuthenticatorProvider provider;

  static LoginView instance;
  factory LoginView(ClientAuthenticatorProvider provider) {
    if (instance == null)
      instance = new LoginView._internal(provider);
    return instance;
  }

  LoginView._internal(this.provider) {
    FB.init();
    GOO.init();
  }

  doNothing(obj) => null;
  
  void fbLogin() {
    FB.login().then((_) => provider.auth = FB).catchError(doNothing);
  }

  void gooLogin() {
    GOO.login().then((_) => provider.auth = GOO).catchError(doNothing);
  }
}
