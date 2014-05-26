import 'dart:io';
import 'dart:async';

import 'package:stream/stream.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:bullet/shared/connector/connector.dart';
import 'package:bullet/shared/connector/impl/websocket/server.dart';

import 'package:bullet/server/database/mongodb.dart';
import 'package:bullet/server/database/server.dart';


void main(List<String> args) {

  var mongo = new MongoDb(new Db('mongodb://localhost/bullet'));

  var permissions = {
    'ads': new DatabasePermissions.all(Permission.ALLOW),
    'people': new DatabasePermissions.all(Permission.AUTHENTICATE)
  };

  Database database = new PermissionsDecorator(mongo, permissions: permissions);

  ConnectorServer<WebSocket> connector = new WebSocketConnectorServer()
    ..bind('db:find',   (data) => database.find(data[0], query: data[1], projection: data[2], live: data[3], metadata: data[4]))
    ..bind('db:insert', (data) => database.insert(data[0], data[1], metadata: data[4]))
    ..bind('db:update', (data) => database.update(data[0], data[1], metadata: data[4]))
    ..bind('db:delete', (data) => database.delete(data[0], data[1], metadata: data[4]));

  var server = new StreamServer(homeDir: '../build/web');

  server
    ..map('ws:/api', connector.add)
    ..map(r'/.*(html|png|js|dart|gif|jpg|jpeg|ttf|woff|css|less)$',
      (HttpConnect connect) => server.resourceLoader.load(connect, connect.request.uri.path))
    ..map('/.+', (HttpConnect connect) => connect.include('/'))
    ..start(address: InternetAddress.ANY_IP_V4, port: 8888);
}