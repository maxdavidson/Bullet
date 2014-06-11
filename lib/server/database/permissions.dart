library bullet.server.database.permissions;

import 'dart:async';
import 'package:bullet/server/authenticator/server.dart';

abstract class Permission {
  static const ALLOW = const AllowPermission();
  static const DENY = const DenyPermission();
  static const AUTHENTICATE = const AuthenticatePermission();
  const Permission();
  Future<bool> authorize(String concern, Object request, Object metadata);
}


class AllowPermission extends Permission {
  const AllowPermission();
  @override
  Future<bool> authorize(String concern, Object request, Object metadata) => new Future.sync(() => true);
}


class DenyPermission extends Permission {
  const DenyPermission();
  @override
  Future<bool> authorize(String concern, Object request, Object metadata) => new Future.sync(() => false);
}


typedef PermissionFn(Object);

class CustomPermission extends Permission {
  final PermissionFn onAuthorize;
  const CustomPermission({this.onAuthorize});
  @override
  Future<bool> authorize(String concern, Object request, Object metadata) =>
    new Future(() {
      if (onAuthorize != null) {
        var result = onAuthorize(request);
        if (result != null && (result is bool || result is Future<bool>))
          return result;
      }
      return false;
    })
    .catchError((_) => false);
}

typedef AuthReactionFn(Authenticator, Object);


class AuthenticatePermission extends Permission {
  final AuthReactionFn onAuthenticate;

  const AuthenticatePermission({this.onAuthenticate});

  @override
  Future<bool> authorize(String concern, Object request, Object metadata) {
    //print('Metadata: $metadata');
    var auth = new ServerAuthenticator.fromJson(metadata);
    //print('Authenticator: $auth');
    return auth.authenticate()
      .then((_) {
        if (onAuthenticate != null) {
          var result = onAuthenticate(auth, request);
          if (result != null && (result is bool || result is Future))
            return result;
        }
        return true;
      })
      .catchError((_) => false);
  }
}


class DatabasePermissions extends Permission {

  final Permission create, read, update, delete;

  // Default constructor with default values.
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
  Future<bool> authorize(String concern, Object request, Object metadata) {
    switch (concern) {
      case 'create':  return authorizeCreate(request, metadata);
      case 'read':    return authorizeRead(request, metadata);
      case 'update:': return authorizeUpdate(request, metadata);
      case 'delete':  return authorizeDelete(request, metadata);
      default:        return null;
    }
  }

  Future<bool> authorizeCreate(Object request, Object metadata) => create.authorize('create', request, metadata);
  Future<bool> authorizeRead(Object request, Object metadata) => read.authorize('read', request, metadata);
  Future<bool> authorizeUpdate(Object request, Object metadata) => update.authorize('update', request, metadata);
  Future<bool> authorizeDelete(Object request, Object metadata) => delete.authorize('delete', request, metadata);

}