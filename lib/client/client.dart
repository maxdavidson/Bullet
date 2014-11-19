library bullet.client;

import 'package:angular/angular.dart';
import 'router.dart';

// Plugins
import 'package:angular/animate/module.dart';

import 'package:connector/connector.dart';
import 'package:connector/websocket.dart';

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


class AppModule extends Module {
  AppModule() {
    bind(RouteInitializerFn, toFactory: routeInitializerFactory, inject: [Injector]);

    install(new AnimationModule());

    install(new DecoratorModule());
    install(new ComponentModule());
    install(new ViewModule());
    install(new FormattersModule());
    install(new EntityModule());

    bind(ClientAuthenticatorProvider);

    bind(Connector, toFactory: () => new Connector.fromStringBus(new WebSocketBus(pathname: 'api')));

    bind(Database, toImplementation: ConnectorProxyDatabase);

    bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
  }
}
