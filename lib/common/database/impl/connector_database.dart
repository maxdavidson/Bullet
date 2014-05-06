part of bullet.common.database;

/**
 * Client
 */
@Injectable()
class ConnectorDatabaseService implements DatabaseService {

  final String prefix = 'db';

  ConnectorClient connector;
  AuthenticationService authentication;

  ConnectorDatabaseService(this.connector, {this.authentication});

  Stream<Map> find(String collection, Map selector, {bool live: false, metaData}) =>
    connector.remoteStream('$prefix:find', {
      'collection': collection,
      'selector': selector,
      'bool': live,
      'metaData': (metaData != null) ? metaData : (authentication != null) ? authentication.serialize() : null
    });

  Future<Map> insert(String collection, Map object, {metaData}) =>
    connector.remoteCall('$prefix:insert', {
      'collection': collection,
      'object': object,
      'metaData': (metaData != null) ? metaData : (authentication != null) ? authentication.serialize() : null
    });

  Future update(String collection, Map object, {metaData}) =>
    connector.remoteCall('$prefix:update', {
      'collection': collection,
      'object': object,
      'metaData': (metaData != null) ? metaData : (authentication != null) ? authentication.serialize() : null
    });

  Future<bool> delete(String collection, Map object, {metaData}) =>
    connector.remoteCall('$prefix:delete', {
      'collection': collection,
      'object': object,
      'metaData': (metaData != null) ? metaData : (authentication != null) ? authentication.serialize() : null
    });

}
