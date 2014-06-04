part of bullet.client.components;

@Component(
  selector: 'navbar',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/navbar/navbar.html',
  cssUrl: '/packages/bullet/client/components/navbar/navbar.css')
class NavbarComponenent {

  final Router router;
  final ClientAuthenticatorProvider provider;

  bool holding = false;

  p() => print('hej');

  NavbarComponenent(this.router, this.provider);

}
