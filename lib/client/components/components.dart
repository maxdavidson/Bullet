library bullet.client.components;

import 'dart:async';
import 'dart:html' as dom;

import 'package:angular/angular.dart';
import 'package:angular/core/module_internal.dart';
import 'package:stream_ext/stream_ext.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';

import 'package:bullet/client/services/authenticator/client.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/shared/stream_helpers.dart';

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
