library bullet.common.database;

import 'dart:async';
export 'dart:async';

import 'package:bullet/common/authenticator/client.dart';
export 'package:bullet/common/authenticator/client.dart';

/**
 * Provides a way to to CRUD operations to a database
 */
abstract class Database {

  AuthenticatorClient authenticator;

  Database(this.authenticator);

  /**
   * Queries the [collection] and a returns an asynchronous stream of result maps.
   * The [query] map follows MongoDb syntax.
   * If [live] is true, then the stream will stay alive and broadcast any new matches.
   * Otherwise, the stream ends when no more entries are found.
   * With [metaData], authentication information can be passed to the server.
   */
  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false, metaData});

  /**
   * Inserts the map [object] into the [collection].
   * If successful, the future returns a map uniquely identifying the object, e.g. { 'id': 1 }.
   */
  Future<Map> insert(String collection, Map object, {metaData});

  /**
   * Updates an existing map [object] in the [collection].
   * If successful, the future completes.
   */
  Future update(String collection, Map object, {metaData});

  /**
   * Deletes an existing map [object] in the [collection].
   * If successful, the future completes.
   */
  Future<bool> delete(String collection, Map object, {metaData});

}