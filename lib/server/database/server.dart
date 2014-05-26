import 'dart:async';
import 'package:bullet/shared/database/database.dart';
import 'package:bullet/server/authenticator/server.dart';

abstract class DatabaseDecorator implements Database {

  final Database delegate;

  DatabaseDecorator(this.delegate);

  @override
  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false, Object metadata}) =>
    delegate.find(collection, query: query, projection: projection, live: live, metadata: metadata);

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

abstract class Permission {
  static const ALLOW = const AllowPermission();
  static const DENY = const DenyPermission();
  static const AUTHENTICATE = const AuthenticatePermission();
  const Permission();
  Future<bool> authorize(Object token, Object metadata);
}

class AllowPermission extends Permission {
  const AllowPermission();
  @override
  Future<bool> authorize(Object token, Object metadata) => new Future.value(true);
}

class DenyPermission extends Permission {
  const DenyPermission();
  @override
  Future<bool> authorize(Object token, Object metadata) => new Future.value(false);
}

class AuthenticatePermission extends Permission {
  const AuthenticatePermission();
  Future<bool> authorize(Object token, Object metadata) =>
    new ServerAuthenticator.fromJson(metadata)
      .authenticate()
      .then((_) => true)
      .catchError((_) => false);
}

var permissions = {
  'ads': const DatabasePermissions(update: Permission.ALLOW, create: Permission.DENY)
};

class DatabasePermissions extends Permission {

  final Permission create;
  final Permission read;
  final Permission update;
  final Permission delete;

  const DatabasePermissions({
    this.create: Permission.DENY,
    this.read:   Permission.ALLOW,
    this.update: Permission.DENY,
    this.delete: Permission.DENY
  });

  const DatabasePermissions.all(Permission permission)
    : create = permission,
      read = permission,
      update = permission,
      delete = permission;

  @override
  Future<bool> authorize(Object token, Object metadata) {
    switch (token) {
      case 'create':  return authorizeCreate(metadata);
      case 'read':    return authorizeRead(metadata);
      case 'update:': return authorizeUpdate(metadata);
      case 'delete':  return authorizeDelete(metadata);
    }
  }

  Future<bool> authorizeCreate(Object metadata) => create.authorize('create', metadata);
  Future<bool> authorizeRead(Object metadata) => read.authorize('read', metadata);
  Future<bool> authorizeUpdate(Object metadata) => update.authorize('update', metadata);
  Future<bool> authorizeDelete(Object metadata) => delete.authorize('delete', metadata);

}

class PermissionsDecorator extends DatabaseDecorator {

  final Map<String, DatabasePermissions> permissions;

  PermissionsDecorator(Database delegate, {this.permissions: const {}}) : super(delegate);

  void _throwIfNotAuthorized(bool authorized) { if (!authorized) throw 'Not authorized!'; }

  @override
  Stream<Map> find(String collection, {Map query, List<String> projection, bool live: false, Object metadata}) {
    if (!permissions.containsKey(collection))
      throw 'No permissions found for collection "$collection".';

    var controller = new StreamController<Map>();
    var permission = permissions[collection] as DatabasePermissions;

    permission.authorizeRead(metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.find(collection, query: query, projection: projection, live: live, metadata: metadata))
      .then(controller.addStream)
      .catchError(controller.addError);

    return controller.stream;
  }

  @override
  Future<Map> insert(String collection, Map object, {Object metadata}) {
    if (!permissions.containsKey(collection))
      throw 'No permissions found for collection "$collection".';

    return (permissions[collection] as DatabasePermissions)
      .authorizeCreate(metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.insert(collection, object));
  }

  @override
  Future update(String collection, Map object, {Object metadata}) {
    if (!permissions.containsKey(collection))
      throw 'No permissions found for collection "$collection".';

    return (permissions[collection] as DatabasePermissions)
      .authorizeUpdate(metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.update(collection, object));
  }

  @override
  Future<bool> delete(String collection, Map object, {Object metadata}){
    if (!permissions.containsKey(collection))
      throw 'No permissions found for collection "$collection".';

    return (permissions[collection] as DatabasePermissions)
      .authorizeDelete(metadata)
      .then(_throwIfNotAuthorized)
      .then((_) => super.delete(collection, object));
  }

}