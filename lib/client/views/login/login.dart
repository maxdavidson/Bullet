part of bullet.client.views;

@Component(
  selector: 'login-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/login/login.html',
  cssUrl: '/packages/bullet/client/views/login/login.css')
class LoginView {
  String query = '';

  AuthenticatorClient FB = new FacebookAuthenticatorClient();
  AuthenticatorClient GOO = new GoogleAuthenticatorClient();

  static LoginView instance;
  factory LoginView() => instance = (instance == null ? new LoginView._internal() : instance);

  LoginView._internal() {
    FB.init();
    GOO.init();
  }
}
