library bullet.client;

import 'package:angular/angular.dart';

part 'router.dart';


class BulletModule extends Module {
  BulletModule() {
    value(RouteInitializerFn, routeInitializer);
    value(NgRoutingUsePushState, new NgRoutingUsePushState.value(false));
  }
}
