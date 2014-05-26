library bullet.client;

import 'package:angular/angular.dart';
import 'router.dart';

// Plugins
import 'package:angular/animate/module.dart';
import 'package:ng_infinite_scroll/ng_infinite_scroll.dart';

// Client modules
import 'components/components.dart';
import 'decorators/decorators.dart';
import 'formatters/formatters.dart';
import 'views/views.dart';
import 'services/database/entities.dart';
import 'services/database/connector.dart';
import 'services/authenticator/client.dart';

// Shared modules
import 'package:bullet/shared/database/database.dart';
import 'package:bullet/shared/connector/impl/websocket/client.dart';


import 'dart:html' as dom;

class AppModule extends Module {
  AppModule() {
    bind(RouteInitializerFn, toValue: routeInitializer);

    install(new AnimationModule());
    install(new InfiniteScrollModule());

    install(new DecoratorModule());
    install(new ComponentModule());
    install(new ViewModule());
    install(new FormatterModule());
    install(new EntityModule());

    bind(ClientAuthenticatorProvider);

    bind(ConnectorClient, toFactory: (Injector i) => new WebSocketConnectorClient(pathname: 'api'));
    bind(Database, toImplementation: ConnectorProxyDatabase);

    bind(dom.Window, toValue: dom.window);
    //bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
  }
}

main() {
  var module = new AppModule();


}