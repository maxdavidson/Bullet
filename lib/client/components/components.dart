library bullet.client.components;

import 'dart:async';
import 'dart:html' as dom;

import 'package:angular/angular.dart';
import 'package:angular/core/module_internal.dart';
import 'package:stream_ext/stream_ext.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';

import 'package:bullet/client/services/authenticator/client.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/shared/helpers.dart';

part 'navbar/navbar.dart';
part 'ad/ad.dart';
part 'loader/loader.dart';

class ComponentModule extends Module {
  ComponentModule() {
    bind(NavbarComponenent);
    bind(AdComponent);
    bind(LoaderComponent);
  }
}
