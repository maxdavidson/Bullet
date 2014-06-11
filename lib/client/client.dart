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


class AppModule extends Module {
  AppModule() {
    bind(RouteInitializerFn, toFactory: routeInitializerFactory);

    install(new AnimationModule());

    // This is broken in pub build, must be fixed for infinite scroll to work on mobile
    install(new InfiniteScrollModule());

    install(new DecoratorModule());
    install(new ComponentModule());
    install(new ViewModule());
    install(new FormattersModule());
    install(new EntityModule());

    bind(ClientAuthenticatorProvider);

    bind(ConnectorClient, toFactory: (Injector i) => new WebSocketConnectorClient(pathname: 'api'));
    bind(Database, toImplementation: ConnectorProxyDatabase);

    //bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
  }
}