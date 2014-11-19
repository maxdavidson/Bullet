library bullet.server.database;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/shared/database/database.dart';
import 'package:bullet/shared/helpers.dart';

import 'permissions.dart';


class DatabaseDecorator implements Database {

  final Database delegate;

  DatabaseDecorator(this.delegate);

  @override
  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) =>
    delegate.find(collection, query: query, fields: fields, orderBy: orderBy, limit: limit, skip: skip, live: live, metadata: metadata);

  @override
  Future<Map> insert(String collection, Map object, {Object metadata}) =>
    delegate.insert(collection, object, metadata: metadata);

  @override
  Future update(String collection, Map object, {Object metadata}) =>
    delegate.update(collection, object, metadata: metadata);

  @override
  Future<bool> delete(String collection, Map object, {Object metadata}) =>
    delegate.update(collection, object, metadata: metadata);

}


class PermissionsDecorator extends DatabaseDecorator {

  final Map<String, DatabasePermissions> permissions;

  PermissionsDecorator(Database delegate, {this.permissions: const {}}) : super(delegate);

  void _throwIfNotAuthorized(bool authorized) {
    if (!authorized) throw 'Not authorized!';
  }

  @override
  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) {

    DatabasePermissions permission = (permissions.containsKey(collection))
      ? permissions[collection]
      : const DatabasePermissions();

    var controller = new StreamController<Map>();

    permission.authorizeRead(query, metadata)
      /*.then((value) {
        print('Collection: $collection, Query: $query, Meta: $metadata, Access: $value');
        return value;
      })*/
      .then(_throwIfNotAuthorized)
      .then((_) => super.find(collection, query: query, fields: fields, orderBy: orderBy, limit: limit, skip: skip, live: live, metadata: metadata))
      .then(controller.addStream)
      .catchError(controller.addError);

    return controller.stream
      .asyncExpand((Map result) =>
        permission.authorizeRead(result, metadata)
          .then((_) => result).asStream());
  }

  @override
  Future<Map> insert(String collection, Map object, {Object metadata}) {
    DatabasePermissions permission = (permissions.containsKey(collection))
      ? permissions[collection]
      : const DatabasePermissions();

    return permission.authorizeCreate(object, metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.insert(collection, object));
  }

  @override
  Future update(String collection, Map object, {Object metadata}) {
    DatabasePermissions permission = (permissions.containsKey(collection))
      ? permissions[collection]
      : const DatabasePermissions();

    return permission.authorizeUpdate(object, metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.update(collection, object));
  }

  @override
  Future<bool> delete(String collection, Map object, {Object metadata}){
    DatabasePermissions permission = (permissions.containsKey(collection))
      ? permissions[collection]
      : const DatabasePermissions();

    return permission.authorizeDelete(object, metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.delete(collection, object));  }
}


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


class UpdateDecorator extends DatabaseDecorator {

  final updateHandlers = new Set<UpdateHandler>();
  
  UpdateDecorator(Database delegate) : super(delegate);

  Future triggerUpdates(String collectionName) {
    print('Updating $collectionName');
    return Future.wait(updateHandlers
      .where((handler) => handler.collectionName == collectionName)
      .map((handler) => handler.update()));
  }
  
  _update(String collectionName) => sideEffect((_) => triggerUpdates(collectionName));
  
  // I'm relying on Mongo still, need to use this for now
  Map _fixMongoDocument(Map document) {
    if (document.containsKey('_id') && document['_id'] is ObjectId)
      document['_id'] = (document['_id'] as ObjectId).toHexString();
  
    if (!document.containsKey('created') && document.containsKey('_id'))
      document['created'] = new ObjectId.fromHexString(document['_id']).dateTime.toIso8601String();
  
    return document;
  }
  
  @override
  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) {
    var dbstream = delegate.find(collection, query: query, fields: fields, orderBy: orderBy, limit: limit, skip: skip, live: live, metadata: metadata);
    
    if (!live) return dbstream;
    
    StreamController<Map> updateController;
    UpdateHandler updateHandler;

    updateController = new StreamController<Map>(
      onListen: () =>
        dbstream.forEach(updateController.add)
          .then((_) => updateHandler = new UpdateHandler(collection, query, fields, updateController, this))
          .then(updateHandlers.add),
        onPause: () { if (updateHandler != null) updateHandler.pause(); },
        onResume: () { if (updateHandler != null) updateHandler.resume(); },
        onCancel: () { updateHandlers.remove(updateHandler); });

    return updateController.stream.map(_fixMongoDocument);
  }
  
  @override
  Future<Map> insert(String collection, Map object, {Object metadata}) =>
    delegate.insert(collection, object, metadata: metadata).then(_update(collection));

  @override
  Future update(String collection, Map object, {Object metadata}) =>
    delegate.update(collection, object, metadata: metadata).then(_update(collection));
  
}
