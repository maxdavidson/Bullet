library bullet.client.components;

import 'package:angular/angular.dart';

import 'navbar/navbar.dart';
import 'ad/ad.dart';
import 'loader/loader.dart';


class ComponentModule extends Module {
  ComponentModule() {
    bind(NavbarComponenent);
    bind(AdComponent);
    bind(LoaderComponent);
  }
}
