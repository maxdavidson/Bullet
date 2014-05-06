library bullet.client;

import 'package:angular/angular.dart';
import 'package:angular/animate/module.dart';
import 'router.dart';

// Client modules
import 'components/components.dart';
import 'views/views.dart';
import 'formatters/formatters.dart';
import 'models/models.dart';

// Shared modules
import '../common/authentication/authentication.dart';
import '../common/connector/impl/websocket_connector/client.dart';

class AppModule extends Module {
  AppModule() {
    bind(RouteInitializerFn, toValue: routeInitializer);

    install(new AnimationModule());
    install(new ComponentModule());
    install(new ViewModule());
    install(new FormatterModule());
    install(new ModelModule());

    //install(new AuthenticationModule());
    bind(AuthenticationService, toImplementation: MockAuthenticationService);

    //install(new DatabaseModule());
    bind(DatabaseService, toImplementation: MockDatabaseService);
  }
}
