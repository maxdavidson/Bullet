library bullet.common.database;

import 'dart:async';
import 'package:di/di.dart';
import 'package:angular/core/annotation_src.dart';
//import 'package:mongo_dart/mongo_dart.dart';
import 'package:bullet/common/authentication/authentication.dart';

part 'impl/connector_database.dart';
part 'impl/mock_database.dart';
//part 'impl/mongodb_database.dart';
part 'collection.dart';

/**
 * Provides a way to to CRUD operations to a database
 */
@Injectable()
abstract class DatabaseService {

  AuthenticationService authentication;

  DatabaseService(this.authentication);

  /**
   * Queries the [collection] and a returns an asynchronous stream of result maps.
   * The [criteria] map follows MongoDb syntax.
   * If [live] is true, then the stream will stay alive and broadcast any new matches.
   * Otherwise, the stream ends when no more entries are found.
   * With [metaData], authentication information can be passed to the server.
   */
  Stream<Map> find(String collection, {Map criteria, bool live: false, metaData});

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