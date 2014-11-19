library bullet.common.database.mongodb;

import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';


/**
 * A MongoDB implementation of the [Database] interface
 */
class MongoDb implements Database {

  final Db mongodb;

  Future _onOpen, _onClose;

  MongoDb(this.mongodb);

  Future open() => (_onOpen == null) ? _onOpen = mongodb.open() : _onOpen;
  Future close() => (_onClose == null) ? _onClose = mongodb.close() : _onClose;

  Map _fixMongoDocument(Map document) {
    if (document.containsKey('_id') && document['_id'] is ObjectId)
      document['_id'] = (document['_id'] as ObjectId).toHexString();

    if (!document.containsKey('created') && document.containsKey('_id'))
      document['created'] = new ObjectId.fromHexString(document['_id']).dateTime.toIso8601String();

    return document;
  }

  @override
  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) {

    if (query != null && query['_id'] != null && query['_id'] is String)
      query['_id'] = new ObjectId.fromHexString(query['_id']);

    String convertField(String field) => (field == 'created' || field == 'id') ? '_id' : field;

    var selector = (query != null && query.containsKey(r'$query')) ? query : { r'$query': query };

    if (orderBy != null) selector[r'$orderby'] = new Map.fromIterables(orderBy.keys.map(convertField), orderBy.values);

    var cursor = mongodb.collection(collection).find(selector);

    if (limit != null) cursor.limit = limit;
    if (skip != null) cursor.skip = skip;
    if (fields != null) cursor.fields = new Map.fromIterable(fields.map(convertField), value: (_) => 1);

    // Cursor's default stream implementation is broken... starts right away and doesn't support pause/resume
    Completer resumer = new Completer.sync()..complete();
    StreamController<Map> dbController;

    // Recursively, asynchronously progress results
    Future progress() => cursor.nextObject()
      .then((Map obj) {
        if (cursor.state != State.CLOSED) {
          if (obj != null) dbController.add(obj);
          return resumer.future.then((_) => progress());
        }
      })
      .catchError(dbController.addError)
      .whenComplete(dbController.close);

    dbController = new StreamController<Map>(
      onListen: () => open().then((_) => progress()),
      onPause: () => resumer = new Completer(),
      onResume: () => resumer.complete(), // Need to evaluate lazily, since resumer may change
      onCancel: cursor.close);

    return dbController.stream.map(_fixMongoDocument);
  }

  @override
  Future<Map> insert(String collection, Map document, {Map metadata}) {
    var id = new ObjectId();
    var hexId = id.toHexString();
    return open()
      .then((_) => mongodb.collection(collection).insert(document..['_id'] = id))
      .then((_) => { '_id': hexId });
  }

  @override
  Future update(String collection, Map object, {Map metadata}) {
    if (object != null && !object.containsKey('_id'))
      throw 'Object must contain id field';
    var copy = {}..addAll(object)..['_id'] = new ObjectId.fromHexString(object['_id']);
    return open()
      .then((_) => mongodb.collection(collection).update({ '_id': copy['_id'] }, copy));
  }

  @override
  Future<bool> delete(String collection, Map object, {Map metadata}) =>
    open().then((_) => mongodb.collection(collection).remove({ '_id': new ObjectId.fromHexString(object['_id']) }));

}
