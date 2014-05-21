library bullet.client.router;

import 'package:angular/angular.dart';

void routeInitializer(Router router, RouteViewFactory views) =>
  views.configure({
    'default': ngRoute(
      defaultRoute: true,
      enter: (RouteEnterEvent e) => router.go('home', { }, replace: false)),
    'home': ngRoute(
      path: '/find',
      viewHtml: '<home-view></home-view>'),
    'find': ngRoute(
      path: '/find/:query',
      viewHtml: '<home-view></home-view>'),
    'login': ngRoute(
      path: '/login',
      viewHtml: '<login-view></login-view>'),
    'user': ngRoute(
      path: '/user/:userId',
      viewHtml: '<profile-view><profile-view>')
  });
