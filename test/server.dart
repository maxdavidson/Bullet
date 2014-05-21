import 'dart:async';

import 'package:stream/stream.dart';
import 'package:bullet/common/connector/impl/websocket/server.dart';

void main() {

  var connector = new WebSocketConnectorServer()
    ..bind('sum', (List<num> list) => list.fold(0, (a, b) => a + b))
    ..bind('hello', (input) => input)
    ..bind('fail', (_) => crashBang())
    ..bind('delayed', (_) => new Future.delayed(const Duration(seconds: 1), () => 'hello'))
    ..bind('stream', (List list) => new Stream.fromIterable(list))
    ..bind('timer', (_) => new Stream.periodic(const Duration(milliseconds: 250), (i) => i++));

  new StreamServer(homeDir: '', uriMapping: {
    'ws:/api': connector.handler
  }).start(port: 1234);

}
