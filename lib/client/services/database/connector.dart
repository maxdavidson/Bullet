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

  const ConnectorProxyDatabase(this.provider, this.connector);

  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) {
    var kwargs = {
      'query': query,
      'fields': fields,
      'orderBy': orderBy,
      'limit': limit,
      'skip': skip,
      'live': live,
      'metadata': metadata == null ? _config : metadata
    };

    bool exists(value) => value != null;
    kwargs = new Map.fromIterables(kwargs.keys.where((key) => exists(kwargs[key])), kwargs.values.where(exists));
    return connector.subscribe('$prefix:find', [collection], kwargs);
  }

  Future<Map> insert(String collection, Map object, {Object metadata}) =>
    connector.subscribe('$prefix:insert', [collection, object], { 'metadata': metadata == null ? _config : metadata }).first;

  Future update(String collection, Map object, {Object metadata}) =>
    connector.subscribe('$prefix:update', [collection, object], { 'metadata': metadata == null ? _config : metadata }).first;

  Future<bool> delete(String collection, Map object, {Object metadata}) =>
    connector.subscribe('$prefix:delete', [collection, object], { 'metadata': metadata == null ? _config : metadata }).first;
}
