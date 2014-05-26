part of bullet.client.components;

@Component(
  selector: 'searcher',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/searcher/searcher.html',
  cssUrl: '/packages/bullet/client/components/searcher/searcher.css',
  map: const { 'autofocus': '=>!autofocus' })
class SearchComponent {
  NgModel ngModel;
  bool autofocus;
  SearchComponent(this.ngModel, NgElement element) {
    //print(element.node.nodes);
  }
}
