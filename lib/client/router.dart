library bullet.client.router;

import 'package:angular/angular.dart';
import 'dart:async';

void routeInitializer(Router router, RouteViewFactory views) =>
  views.configure({
    'default': ngRoute(
      defaultRoute: true,
      enter: (RouteEnterEvent e) => router.go('home', {}, replace: false)),
    'home': ngRoute(
      path: '/',
      viewHtml: '<home-view></home-view>'),
    'find': ngRoute(
      path: '/find/:query',
      viewHtml: '<home-view></home-view>',
      preEnter: (RoutePreEnterEvent e) {
        var query = e.parameters['query'] as String;
        if (query.isEmpty)
          router.go('home', {}, replace: true);
      }),
    'ad': ngRoute(
      path: '/ad/:adId',
      viewHtml: '<ad-view></ad-view>'),
    'login': ngRoute(
      path: '/login',
      viewHtml: '<login-view></login-view>'),
    'user': ngRoute(
      path: '/user/:userId',
      viewHtml: '<profile-view><profile-view>')
  });
