import 'dart:io';
import 'dart:async';

import 'package:stream/stream.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/shared/connector/connector.dart';
import 'package:bullet/shared/connector/impl/websocket/server.dart';

import 'package:bullet/server/database/mongodb.dart';
import 'package:bullet/server/database/server.dart';


const HOME = '../web';
//const HOME = '../build/web';

/**
 * The main database implementation
 */
final Database database = new MongoDb(new Db('mongodb://127.0.0.1/bullet'));

final userState = new Map<String, Future<Map>>();


/**
 * A helper function to find or otherwise create a user
 */
Future<Map> findOrCreateUser(Authenticator auth) {
  var key = [auth.type, auth.userId].join('.');
  var account = { 'type': auth.type, 'id': auth.userId };

  if (!userState.containsKey(key)) {
    print('caching future');
    userState[key] = database.find('users', query: { 'accounts': { r'$elemMatch': account } }).first
      .then(sideEffect((_) => print('found user')))
      .catchError((e) {
        print('did not find user for ${auth.type}. trying to match by name or email...');
        return database.find('users', query: { r'$or': [{ 'email': auth.email }, { 'name': auth.userName }]}).first
          .then((Map user) {
            print('found matching user. updating with additional info...');
            user['accounts'].add(account);
            return database.update('users', user)
              .then((_) => user);
          })
          .catchError((e) {
            print('did not find matching user. creating new user...');
            var user = { 'name': auth.userName, 'email': auth.email, 'ads': [], 'accounts': [account] };
            return database.insert('users', user)
              .then((Map id) => user..addAll(id));
          });
      });
  }

  return userState[key].then(sideEffect((Map user) => print('retreived user ${user['name']}')));
}

/**
 * A [Permission] object that only allows access if user is logged in
 */
Permission authenticateAsUser = new AuthenticatePermission(
  onAuthenticate: (Authenticator auth, Map request) =>
    findOrCreateUser(auth).then((_) => true));

/**
 * A [Permission] object that only allows access if a user is logged in and owns the ad
 */
Permission authenticateAsUserWhoOwnsAd = new AuthenticatePermission(
  onAuthenticate: (Authenticator auth, Map request) =>
    findOrCreateUser(auth).then((Map user) => user['ads'].contains(request['_id'])));

/**
 * The set of permissions for the database
 */
Map<String, DatabasePermissions> permissions = {
    'ads': new DatabasePermissions(
        read:   Permission.ALLOW,
        create: authenticateAsUser,
        update: authenticateAsUserWhoOwnsAd,
        delete: authenticateAsUserWhoOwnsAd),
    'users': new DatabasePermissions(
        read:   authenticateAsUser,
        create: Permission.DENY,
        update: authenticateAsUser,
        delete: Permission.DENY)
};

/**
 * The permission-wrapped database
 */
Database wrappedDatabase = new PermissionsDecorator(database, permissions: permissions);

/**
 * Hooks for the API
 */
var API = <String, Function> {
    'db:find':   wrappedDatabase.find,
    'db:insert': wrappedDatabase.insert,
    'db:update': wrappedDatabase.update,
    'db:delete': wrappedDatabase.delete
};

/**
 * Create the connector instance
 */
ConnectorServer<WebSocket> connector = new WebSocketConnectorServer();



void main(List<String> args) {

  /**
   * Bind API hooks to the connector
   */
  API.forEach(connector.bind);

  /**
   * Create the web server
   */
  var server = new StreamServer(homeDir: HOME);

  /**
   * Bind websocket to path and start server in push-state mode,
   * redirecting all but specific requests to index.html
   */
  server
    ..map('ws:/api', connector.add)
    ..map(r'/.*(html|png|js|dart|gif|jpg|jpeg|ttf|woff|css|less|svg)$',
      (HttpConnect connect) => server.resourceLoader.load(connect, connect.request.uri.path))
    ..map('/.+', (HttpConnect connect) => connect.include('/'))
    ..start(address: InternetAddress.ANY_IP_V4, port: 8888);
}