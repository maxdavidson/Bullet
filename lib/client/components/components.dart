library bullet.client.components;

import 'dart:math';
import 'dart:async';
import 'package:angular/angular.dart';
import 'package:bullet/client/models/models.dart';

part 'navbar/navbar.dart';
part 'adset/adset.dart';
part 'ad/ad.dart';
part 'searcher/searcher.dart';

class ComponentModule extends Module {
  ComponentModule() {
    bind(NavbarComponenent);
    bind(AdsetComponent);
    bind(AdComponent);
    bind(SearchComponent);
  }
}
