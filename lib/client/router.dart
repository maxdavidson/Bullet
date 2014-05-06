library bullet.client.router;

import 'package:angular/angular.dart';

void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'root': ngRoute(
      defaultRoute: true,
      path: '/',
      viewHtml: '<home-view></home-view>'
    )
  });
}
