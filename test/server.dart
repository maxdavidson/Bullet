import 'dart:async';

import 'package:stream/stream.dart';
import 'package:bullet/common/connector/websocket/server.dart';

void main() {

  var connector = new WebSocketConnectorServer()
    ..setHandle('sum', (List<num> list) => list.fold(0, (a, b) => a + b))
    ..setHandle('hello', (input) => input)
    ..setHandle('fail', (_) => crashBang())
    ..setHandle('delayed', (_) => new Future.delayed(const Duration(seconds: 1), () => 'hello'))
    ..setHandle('stream', (List list) => new Stream.fromIterable(list))
    ..setHandle('timer', (_) => new Stream.periodic(const Duration(milliseconds: 250), (i) => i++));

  new StreamServer(homeDir: '../web', uriMapping: {
    'ws:/api': connector.handle
  }).start(port: 8888);

}
