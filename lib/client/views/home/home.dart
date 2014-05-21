part of bullet.client.views;

@Component(
  selector: 'home-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/home/home.html',
  cssUrl: '/packages/bullet/client/views/home/home.css')
class HomeView {
  // A synced variable, not a reference, and thus needs to have an initial value
  String query = '';

  HomeView(Scope scope, Router router, RouteProvider rp) {
    if (rp.parameters.containsKey('query')) query = rp.parameters['query'];
  }
}
