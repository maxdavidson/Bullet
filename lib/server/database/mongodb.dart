library bullet.common.database.mongodb;

import 'dart:async';

import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';

/*
// { 'title': { r'$regex': query, r'$options': 'i' }

typedef S Lambda<T,S>(T);
typedef bool Predicate<T>(T);

/**
 * Very limited fake MongoDB search, for now.
 * Returns false for unimplemented features to prevent false positives.
 */
Predicate<Map> filter(Map criteria) => (Map document) {
  if (criteria == null) return true;

  Map operatorHandlers = {
      r'$gt': (value, comparator, _) => value > comparator,
      r'$lt': (value, comparator, _) => value < comparator,
      r'$regex': (value, regex, Map operators) {
        String options = operators.containsKey(r'$options') ? operators[r'$options'] : '';
        return new RegExp(regex, multiLine: options.contains('m'), caseSensitive: !options.contains('i')).hasMatch(value);
      }
  };

  bool handleOperatorMap(Map operatorMap, compareValue) {
    String handler = operatorHandlers.keys.firstWhere(operatorMap.containsKey, orElse: () => null);
    if (handler == null) return false;
    return operatorHandlers[handler](compareValue, operatorMap[handler], operatorMap);
  }

  return criteria.keys.every((String field) {

    if (criteria[field] is String || criteria[field] is num)
      return criteria[field] == document[field];

    if (criteria[field] is Map)
      return handleOperatorMap(criteria[field], document[field]);

    return false;
  });
};


Lambda<Map, Map> project([List projection = const []]) => (Map map) {
  if (projection == null) return map;
  return new Map.fromIterable(map.keys.where(projection.contains), value: (key) => map[key]);
};
*/


class UpdateHandler {
  final String collectionName;
  final Map query;
  final List<String> fields;
  final StreamController<Map> controller;
  final Database db;

  DateTime lastUpdated;
  bool _paused = false;

  UpdateHandler(this.collectionName, this.query, this.fields, this.controller, this.db)
    : lastUpdated = new DateTime.now();

  void pause() { _paused = true; }
  Future resume() { _paused = false; return update(); }

  get _adjustedQuery {
    var last = lastUpdated.toIso8601String();
    return new Map.from(query)..addAll({ r'$or': [{ 'updated': { r'$gt': last } }, { 'created': { r'$gt': last } }] });
  }

  Future update() => _paused ? new Future.value(null) :
    db.find(collectionName, query: _adjustedQuery, fields: fields, live: false)
      .map(sideEffect((map) => print('Updated $map')))
      .forEach(controller.add)
      .then(sideEffect(((_) => lastUpdated = new DateTime.now())));
}

/**
 * A MongoDB implementation of the [Database] interface
 */
class MongoDb implements Database {

  final Db mongodb;
  final updateHandlers = new Set<UpdateHandler>();

  Future _onOpen, _onClose;

  MongoDb(this.mongodb);

  Future open() => (_onOpen == null) ? _onOpen = mongodb.open() : _onOpen;
  Future close() => (_onClose == null) ? _onClose = mongodb.close() : _onClose;

  Future _triggerUpdates(String collectionName) {
    print('Updating $collectionName');
    return Future.wait(updateHandlers
      .where((handler) => handler.collectionName == collectionName)
      .map((handler) => handler.update()));
  }

  Map _fixDocument(Map document) {
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

    var selector = (query != null && query.containsKey(r'$query')) ? query : { r'$query': query};

    if (orderBy != null) selector[r'$orderby'] = new Map.fromIterables(orderBy.keys.map(convertField), orderBy.values);

    var cursor = mongodb.collection(collection).find(selector);

    if (limit != null) cursor.limit = limit;
    if (skip != null) cursor.skip = skip;
    if (fields != null) cursor.fields = new Map.fromIterable(fields.map(convertField), value: (_) => 1);

    // print('Selector: ${cursor.selector}, Sort: ${cursor.sort}, Fields: ${cursor.fields}, Limit: ${cursor.limit}, Skip: ${cursor.skip}');

    // Cursor's default stream implementation is broken... starts right away and doesn't support pause/resume
    Completer onResume = new Completer.sync()..complete();
    StreamController<Map> dbController;

    // Recursively, asynchronously progress results
    Future progress() => cursor.nextObject()
      .then((Map obj) {
        if (cursor.state != Cursor.CLOSED) {
          if (obj != null) dbController.add(obj);
          return onResume.future.then((_) => progress());
        }
      })
      .catchError(dbController.addError)
      .whenComplete(dbController.close);

    dbController = new StreamController<Map>(
      onListen: () => open().then((_) => progress()),
      onPause: () => onResume = new Completer(),
      onResume: onResume.complete,
      onCancel: cursor.close);

    if (!live) return dbController.stream.map(_fixDocument);

    noOp() => null;

    StreamController<Map> updateController;
    UpdateHandler updateHandler;

    updateController = new StreamController<Map>(
      onListen: () =>
        dbController.stream
          .forEach(updateController.add)
          .then((_) => updateHandler = new UpdateHandler(collection, query, fields, updateController, this))
          .then(updateHandlers.add),
        onPause: () => (updateHandler == null) ? noOp : updateHandler.pause(),
        onResume: () => (updateHandler == null) ? noOp : updateHandler.resume(),
        onCancel: () => updateHandlers.remove(updateHandler));

    return updateController.stream.map(_fixDocument);
  }

  @override
  Future<Map> insert(String collection, Map document, {Map metadata}) {
    var id = new ObjectId();
    var hexId = id.toHexString();
    return open()
      .then((_) => mongodb.collection(collection).insert(document..['_id'] = id))
      .then(sideEffect((_) => _triggerUpdates(collection)))
      .then((_) => { '_id': hexId });
  }

  @override
  Future update(String collection, Map object, {Map metadata}) {
    if (object != null && !object.containsKey('_id'))
      throw 'Object must contain id field';
    var copy = {}..addAll(object)..['_id'] = new ObjectId.fromHexString(object['_id']);
    return open()
      .then((_) => mongodb.collection(collection).update({ '_id': copy['_id'] }, copy))
      .then(sideEffect((_) => _triggerUpdates(collection)));
  }

  @override
  Future<bool> delete(String collection, Map object, {Map metadata}) =>
    open().then((_) => mongodb.collection(collection).remove({ '_id': new ObjectId.fromHexString(object['_id']) }));

}
