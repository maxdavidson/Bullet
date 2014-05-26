library bullet.client.decorators;

import 'package:angular/angular.dart';
import 'dart:html' as dom;

part 'link.dart';

class DecoratorModule extends Module {
  DecoratorModule() {
    bind(Link);
  }
}