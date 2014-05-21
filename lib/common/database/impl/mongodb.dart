library bullet.common.database.mongodb;

import 'package:stream_ext/stream_ext.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:bullet/common/database/database.dart';
export 'package:bullet/common/database/database.dart';

Function filter(Map criteria) =>
  (Map map) => (criteria == null)
    ? true
    : criteria.keys.every((key) => (map[key] is String)
      ? map[key].toLowerCase().contains(criteria[key].toString().toLowerCase())
      : map[key] == criteria[key]);

Function project(List projection) =>
  (Map map) => map.keys
    .where((key) => (projection == null) || projection.contains(key))
    .fold({}, (newMap, key) => newMap..[key] = map[key]);

class MongoDb implements Database {

  Db mongodb;
  AuthenticatorClient authentication;
  MongoDb(this.authentication, this.mongodb);

  final updates = new StreamController<Map>.broadcast();

  Stream<Map> find(String collection, {Map query, List projection, bool live: false, metaData}) {

    if (query != null && query['_id'] != null && query['_id'] is String)
      query['_id'] = new ObjectId.fromHexString(query['_id']);

    Function close;
    StreamController<Map> controller;
    controller = new StreamController<Map>(
      onListen: () =>
        mongodb.open()
          .then((_) {
            var cursor = mongodb.collection(collection).find(query);
            close = cursor.close;
            var stream = cursor.stream
              .map((Map map) => map..['created']=(map['_id'].value as ObjectId).dateTime.toIso8601String())
              .map((Map map) => map..['_id']=(map['_id'].value as ObjectId).toHexString());

            if (live) stream = StreamExt.concat(stream, updates.stream.where(filter(query))).map(project(projection));

            return stream.pipe(controller);
          })
          .catchError(controller.addError)
          .whenComplete(close),
      onCancel: close
    );
    return controller.stream;
  }

  Future<Map> insert(String collection, Map object, {metaData}) {
    mongodb
      .open()
      .then((_) => mongodb.collection(collection).insert(object));
      // TODO
  }

  Future update(String collection, Map object, {metaData}) {
    // TODO
  }

  Future<bool> delete(String collection, Map object, {metaData}) {
    // TODO
  }

}
