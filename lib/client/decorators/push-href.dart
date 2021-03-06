library bullet.client.decorators.push_href;

import 'dart:html' as DOM;
import 'package:angular/angular.dart';

@Decorator(
    selector: 'a[push-href]',
    map: const {'push-href': '@href'})
class PushHref {

  final DOM.Element element;
  final NgElement ngElement;
  final NgRoutingUsePushState routing;
  final RouteProvider rp;
  final Router router;

  String url;

  void set href(value) {
    url = value;
    var injectedUrl = createUrl(url);
    if (!routing.usePushState)
      injectedUrl = '#' + injectedUrl;
    ngElement.setAttribute('href', injectedUrl);
  }

  String createUrl(String url) => url.startsWith('/')
    ? url
    : rp.route.path.reverse(tail: url);

  PushHref(this.element, this.ngElement, this.routing, this.router, this.rp, VmTurnZone zone) {
    zone.runOutsideAngular(() {
      if (routing.usePushState) {
        element.onClick.listen((event) {
          if (!event.ctrlKey && !event.metaKey) {
            event.preventDefault();
            router.gotoUrl(createUrl(url));
          }
        });
      }
    });
  }
}
