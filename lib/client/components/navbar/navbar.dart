part of bullet.client.components;

@Component(
  selector: 'navbar',
  publishAs: 'ctrl',
  templateUrl: 'packages/bullet/client/components/navbar/navbar.html',
  cssUrl: const[
    'packages/bullet/client/components/navbar/navbar.css',
    'css/foundation.min.css'
  ])
class NavbarComponenent {
  bool isExpanded = false;
  toggleExpander() { isExpanded = !isExpanded; }
}
