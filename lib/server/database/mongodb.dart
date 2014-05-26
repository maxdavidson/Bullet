library bullet.common.database.mongodb;

import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/server/authenticator/server.dart';
import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';


// Limited mongodb filter
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

  final Db mongodb;
  final updates = new StreamController<Map>.broadcast();

  MongoDb(this.mongodb);

  @override
  Stream<Map> find(String collection, {Map query, List projection, bool live: false, Map metadata}) {

    if (query != null && query['_id'] != null && query['_id'] is String)
      query['_id'] = new ObjectId.fromHexString(query['_id']);

    Function close = () => null;
    StreamController<Map> controller;

    controller = new StreamController<Map>(
      onListen: () {
        mongodb.open()
          .then((_) {
            var cursor = mongodb.collection(collection).find(query);
            close = cursor.close;
            return cursor.stream
              .map((Map map) => map..['created']=(map['_id'].value as ObjectId).dateTime.toIso8601String())
              .map((Map map) => map..['_id']=(map['_id'].value as ObjectId).toHexString())
              .forEach(controller.add)
              .then((_) { if (live) updates.stream.where(filter(query)).forEach(controller.add); });
          })
          .catchError(controller.addError)
          .whenComplete(close)
          .then((_) => mongodb.close());
      },
      onCancel: close
    );

    return controller.stream.map(project(projection));
  }

  @override
  Future<Map> insert(String collection, Map object, {Map metadata}) {
    mongodb
      .open()
      .then((_) => mongodb.collection(collection).insert(object));
      // TODO
  }

  @override
  Future update(String collection, Map object, {Map metadata}) {
    // TODO
  }

  @override
  Future<bool> delete(String collection, Map object, {Map metadata}) {
    // TODO
  }

}
