library bullet.common.database.connector;

import 'package:angular/angular.dart'; // For @Injectable annotation
import 'package:bullet/common/connector/connector.dart';
import 'package:bullet/common/database/database.dart';
export 'package:bullet/common/database/database.dart';

/**
 * Client
 */
@Injectable()
class ConnectorProxy implements Database {

  final String prefix = 'db';

  ConnectorClient connector;
  AuthenticatorClient authenticator;

  ConnectorProxy(this.authenticator, this.connector);

  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false, metaData}) =>
    connector.subscribe('$prefix:find', [collection, query, projection, live, metaData]);

  Future<Map> insert(String collection, Map object, {metaData}) =>
    connector.subscribe('$prefix:insert', [collection, object, metaData]).first;

  Future update(String collection, Map object, {metaData}) =>
    connector.subscribe('$prefix:update', [collection, object, metaData]).first;

  Future<bool> delete(String collection, Map object, {metaData}) =>
    connector.subscribe('$prefix:delete', [collection, object, metaData]).first;

}
