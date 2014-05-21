library bullet.client.components;

import 'dart:async';
import 'package:angular/angular.dart';
import 'package:angular/core/module_internal.dart';
import 'package:stream_ext/stream_ext.dart';
import 'package:bullet/client/models/models.dart';
import 'package:bullet/client/stream_helpers.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';

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
