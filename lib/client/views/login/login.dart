library bullet.client.views.login;

import 'dart:async';

import 'package:angular/angular.dart';

import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/client/services/authenticator/client.dart';
import 'package:bullet/client/services/authenticator/impl/google.dart';
import 'package:bullet/client/services/authenticator/impl/facebook.dart';


@Component(
    selector: 'login-view',
    templateUrl: 'login.html',
    cssUrl: const ['login.css', '../views.css'])
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
