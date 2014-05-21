import 'dart:io';
import 'dart:async';

import 'package:stream/stream.dart';

import 'package:bullet/common/database/database.dart';
import 'package:bullet/common/database/impl/mock.dart';
import 'package:bullet/common/database/impl/mongodb.dart';

import 'package:bullet/common/connector/connector.dart';
import 'package:bullet/common/connector/impl/websocket/server.dart';

import 'package:mongo_dart/mongo_dart.dart';

void main(List<String> args) {

  Db db = new Db('mongodb://localhost/bullet');
  Database database = new MongoDb(null, db);

  ConnectorServer<WebSocket> connector = new WebSocketConnectorServer()
    ..bind('db:find',   (data) => database.find(data[0], query: data[1], projection: data[2], live: data[3], metaData: data[4]))
    ..bind('db:insert', (data) => database.insert(data[0], data[1], metaData: data[4]))
    ..bind('db:update', (data) => database.update(data[0], data[1], metaData: data[4]))
    ..bind('db:delete', (data) => database.delete(data[0], data[1], metaData: data[4]));

  var server = new StreamServer(homeDir: '../build/web');

  server
    ..map('ws:/api', connector.add)
    ..map(r'/.*(html|png|js|dart|gif|jpg|jpeg|ttf|woff|css|less)$',
      (HttpConnect connect) => server.resourceLoader.load(connect, connect.request.uri.path))
    ..map('/.+', (HttpConnect connect) => connect.include('/'))
    ..start(address: InternetAddress.ANY_IP_V4, port: 8888);

}