library bullet.database;

import 'dart:async';

import 'package:bullet/shared/authenticator/authenticator.dart';
export 'package:bullet/shared/authenticator/authenticator.dart';


/**
 * Provides a way to to CRUD operations to a database
 */
abstract class Database {

  /**
   * Queries the [collection] and a returns an asynchronous stream of result maps.
   * The [query] map follows MongoDb syntax.
   * If [live] is true, then the stream will stay alive and broadcast any new matches.
   * Otherwise, the stream ends when no more entries are found.
   */
  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false, Object metadata});

  /**
   * Inserts the map [object] into the [collection].
   * If successful, the future returns a map uniquely identifying the object, e.g. { 'id': 1 }.
   */
  Future<Map> insert(String collection, Map object, {Object metadata});

  /**
   * Updates an existing map [object] in the [collection].
   * If successful, the future completes.
   */
  Future update(String collection, Map object, {Object metadata});

  /**
   * Deletes an existing map [object] in the [collection].
   * If successful, the future completes.
   */
  Future<bool> delete(String collection, Map object, {Object metadata});

}