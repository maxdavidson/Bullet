library bullet.client.components.navbar;

import 'package:angular/angular.dart';
import 'package:bullet/client/services/authenticator/client.dart';


@Component(
  selector: 'navbar',
  templateUrl: 'navbar.html',
  cssUrl: 'navbar.css')
class NavbarComponenent {

  final Router router;
  final ClientAuthenticatorProvider provider;

  bool holding = false;

  NavbarComponenent(this.router, this.provider);

}
