library bullet.client.router;

import 'dart:async';
import 'package:angular/angular.dart';
import 'package:bullet/client/services/authenticator/client.dart';

Function preventEnter(Injector inj, Router router, {bool whenLoggedIn: false}) =>
  (RouteEvent e) {
    if (inj.get(ClientAuthenticatorProvider).isLoggedIn == whenLoggedIn)
      router.go('default', {}, replace: false);
  };

String titleBuilder([String page]) => (page == null) ? 'Bullet' : '$page | Bullet';

Function setTitle([String page]) {}

/**
 * Need to do some funky closure stuff to get a reference to the injector
 */
RouteInitializerFn routeInitializerFactory(Injector inj) =>
  (Router router, RouteViewFactory views) =>
    views.configure({
      'default': ngRoute(
        defaultRoute: true,
        enter: (RouteEnterEvent e) => router.go('search', {}, replace: false)),
      'search': ngRoute(
        path: '/search',
        mount: {
          'find': ngRoute(
            defaultRoute: true,
            path: '/:query',
            viewHtml: '<search-view></search-view>'),
        }),
      'ad': ngRoute(
        path: '/ad/:adId',
        viewHtml: '<ad-view></ad-view>'),
      'new': ngRoute(
        path: '/new',
        preEnter: preventEnter(inj, router),
        viewHtml: '<create-ad-view></create-ad-view>'),
      'login': ngRoute(
        path: '/login',
        preEnter: preventEnter(inj, router, whenLoggedIn: true),
        viewHtml: '<login-view></login-view>'),
      'profile': ngRoute(
        path: '/profile/:userId',
        viewHtml: '<profile-view></profile-view>')
    });