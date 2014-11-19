library bullet.client.decorators;

import 'package:angular/angular.dart';

import 'push-href.dart';


class DecoratorModule extends Module {
  DecoratorModule() {
    bind(PushHref);
  }
}
