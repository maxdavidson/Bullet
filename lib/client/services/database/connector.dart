library bullet.client.database.connector;

import 'dart:async';

import 'package:angular/angular.dart';

import 'package:bullet/client/services/authenticator/client.dart';

import 'package:bullet/shared/connector/connector.dart';
import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';


/**
 * Client
 */
@Injectable()
class ConnectorProxyDatabase implements Database {

  static final String prefix = 'db';

  final ConnectorClient connector;
  final ClientAuthenticatorProvider provider;

  Authenticator get authenticator => provider.auth;

  Map get _config => authenticator == null ? null : authenticator.config;

  ConnectorProxyDatabase(this.provider, this.connector);

  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false}) =>
    connector.subscribe('$prefix:find', [collection, query, projection, live, _config]);

  Future<Map> insert(String collection, Map object) =>
    connector.subscribe('$prefix:insert', [collection, object, _config]).first;

  Future update(String collection, Map object) =>
    connector.subscribe('$prefix:update', [collection, object, _config]).first;

  Future<bool> delete(String collection, Map object) =>
    connector.subscribe('$prefix:delete', [collection, object, _config]).first;
}
