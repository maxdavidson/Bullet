part of bullet.client.components;

@Component(
  selector: 'navbar',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/navbar/navbar.html',
  cssUrl: '/packages/bullet/client/components/navbar/navbar.css')
class NavbarComponenent {
  Router router;

  NavbarComponenent(this.router);

  goTo(String view) => router.go(view, {});

  bool isExpanded = false;
  toggleExpander() { isExpanded = !isExpanded; }
}
