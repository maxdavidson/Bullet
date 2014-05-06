part of bullet.client.views;

@Component(
  selector: 'home-view',
  publishAs: 'ctrl',
  templateUrl: 'packages/bullet/client/views/home/home.html')
class HomeView {
  // A synced variable, not a reference, and thus needs to have an initial value
  String query = ''; 
}