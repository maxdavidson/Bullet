part of bullet.client;

void routeInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'root': ngRoute(
      defaultRoute: true,
      path: '/',
      view: 'views/test.html'
    )
  });
}
