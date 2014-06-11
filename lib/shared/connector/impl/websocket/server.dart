library bullet.connector.websocket.server;

import 'dart:io';
import 'dart:async';

import 'package:quiver/async.dart';

import 'package:bullet/shared/connector/connector.dart';
export 'package:bullet/shared/connector/connector.dart';

import 'src/event.dart';

Stream convertToStream(input) {;
  if (input is Stream) return input;
  else if (input is Future) { // Recursively deal with futures. For example, Future<Stream> is converted to Stream
    var controller = new StreamController();
    input.then((completion) => convertToStream(completion).pipe(controller));
    return controller.stream;
  }
  else return new Future.value(input).asStream();
}

/**
 * Defines a class that handles remote procedures
 */
class WebSocketConnectorServer implements ConnectorServer<WebSocket> {

  final subscriptions = new Map<String, StreamSubscription>();
  final handlers = new Map<String, Function>();

  @override
  void bind(String identifier, Function handler) { handlers[identifier] = handler; }

  @override
  void unbind(String identifier) { handlers.remove(identifier); }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) => null;

  @override
  void close() {
    Future.wait(subscriptions.values.map((StreamSubscription subscription) => subscription.cancel()));
  }

  const WebSocketConnectorServer();

  Future addStream(Stream<WebSocket> stream) => stream.forEach(add);
  Future cancel() => Future.wait(subscriptions.values.map((sub) => sub.cancel()));

  @override
  add(WebSocket ws) => ws
    .map((json) { print('Received: $json'); return json; })
    .transform(CONNECTOREVENT.decoder)
    .transform(new StreamTransformer.fromHandlers(
      handleData: (ConnectorEvent event, EventSink<ConnectorEvent> sink) {
        var subscription = subscriptions[event.id];
        noOp() => null;
        new PubSub()
          ..on(ConnectorEvent.PING, () => sink.add(event))
          ..on(ConnectorEvent.PAUSE, subscription == null ? noOp : subscription.pause)
          ..on(ConnectorEvent.RESUME, subscription == null ? noOp : subscription.resume)
          ..on(ConnectorEvent.CANCEL, subscription == null ? noOp : subscription.cancel)
          ..on(ConnectorEvent.CALL, () {
            var kwargs = new Map.fromIterables(event.kvargs.keys.map((key) => new Symbol(key)), event.kvargs.values);
            var result = Function.apply(handlers[event.event], event.args, kwargs);
            var stream = convertToStream(result).map((value) => new ConnectorEvent.fromEvent(event, type: ConnectorEvent.EVENT, args: [value]));

            subscriptions[event.id] = stream.listen((value) {
              if (ws.readyState == WebSocket.OPEN)
                sink.add(value);
              else
                subscriptions[event.id].cancel();
              }, 
              onDone: () {
                sink.add(new ConnectorEvent.fromEvent(event, type: ConnectorEvent.END));
                subscriptions.remove(event.id);
              },
              onError: (error, StackTrace trace) => sink.add(new ConnectorEvent.fromEvent(event, 
                  type: ConnectorEvent.ERROR, args: [error.toString(), trace.toString()]))
            );
          })
          ..trigger(event.type);
      }
    ))
    .transform(CONNECTOREVENT.encoder)
    .map((json) { print('Sent: $json'); return json; })
    .pipe(ws);
}
