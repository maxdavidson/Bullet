library bullet.client.components.loader;

import 'package:angular/angular.dart';


@Component(
  selector: 'loader',
  templateUrl: 'loader.html',
  cssUrl: 'loader.css',
  map: const { 'size': '=>size' })
class LoaderComponent {
  String _size = '1em';
  get size => _size;
  set size(val) => _size = '${val}em';
}
