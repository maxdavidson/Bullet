import 'dart:async';

import 'package:stream/stream.dart';
import 'package:bullet/common/connector/impl/websocket_connector/server.dart';

void main() {

  var connector = new WebSocketConnectorServer()
    ..setHandler('sum', (List<num> list) => list.fold(0, (a, b) => a + b))
    ..setHandler('hello', (input) => input)
    ..setHandler('fail', (_) => crashBang())
    ..setHandler('delayed', (_) => new Future.delayed(const Duration(seconds: 1), () => 'hello'))
    ..setHandler('stream', (List list) => new Stream.fromIterable(list))
    ..setHandler('timer', (_) => new Stream.periodic(const Duration(milliseconds: 250), (i) => i++));

  new StreamServer(homeDir: '../web', uriMapping: {
    'ws:/api': connector.handler
  }).start(port: 8888);

}
