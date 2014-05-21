library bullet.client;

import 'package:angular/angular.dart';
import 'router.dart';

// Plugins
import 'package:angular/animate/module.dart';
import 'package:ng_infinite_scroll/ng_infinite_scroll.dart';

// Client modules
import 'components/components.dart';
import 'formatters/formatters.dart';
import 'models/models.dart';
import 'views/views.dart';

// Shared modules
import 'package:bullet/common/authenticator/client.dart';
import 'package:bullet/common/database/database.dart';
import 'package:bullet/common/connector/connector.dart';

import 'package:bullet/common/database/impl/mock.dart';
import 'package:bullet/common/database/impl/connector.dart';
import 'package:bullet/common/connector/impl/websocket/client.dart';

class AppModule extends Module {
  AppModule() {
    bind(RouteInitializerFn, toValue: routeInitializer);

    install(new AnimationModule());
    //install(new InfiniteScrollModule());

    install(new ComponentModule());
    install(new ViewModule());
    install(new FormatterModule());
    install(new EntityMapperModule());

    bind(AuthenticatorClient, toValue: null);
    bind(ConnectorClient, toValue: new WebSocketConnectorClient(pathname: 'api'));
    bind(Database, toImplementation: ConnectorProxy);

    //bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
  }
}
