part of bullet.client.components;

@Component(
  selector: 'loader',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/loader/loader.html',
  cssUrl: '/packages/bullet/client/components/loader/loader.css',
  map: const { 'size': '=>size' })
class LoaderComponent {
  String _size = '1em';
  get size => _size;
  set size(val) => _size = '${val}em';
}
