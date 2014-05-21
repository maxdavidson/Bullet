part of bullet.client.components;

@Component(
  selector: 'searcher',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/searcher/searcher.html',
  cssUrl: '/packages/bullet/client/components/searcher/searcher.css')
class SearchComponent {
  NgModel ngModel;
  SearchComponent(this.ngModel);
}
