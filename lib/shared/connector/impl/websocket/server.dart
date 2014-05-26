library bullet.connector.websocket.server;

import 'dart:io';
import 'dart:async';

import 'package:bullet/shared/connector/connector.dart';
export 'package:bullet/shared/connector/connector.dart';

import 'src/event.dart';


/**
 * Defines a class that handles remote procedures
 */
class WebSocketConnectorServer implements ConnectorServer<WebSocket> {

  final subscriptions = new Map<String, StreamSubscription>();
  final handlers = new Map<String, Function>();

  void bind(String identifier, handler(dynamic)) { handlers[identifier] = handler; }

  void unbind(String identifier) { handlers.remove(identifier); }

  void addError(errorEvent, [StackTrace stackTrace]) => null;

  void close() {
    Future.wait(subscriptions.values.map((StreamSubscription subscription) => subscription.cancel()));
  }

  Future addStream(Stream<WebSocket> stream) => stream.forEach(add);
  Future cancel() => Future.wait(subscriptions.values.map((sub) => sub.cancel()));

  add(WebSocket ws) => ws
    .transform(CONNECTOREVENT.decoder)
    .transform(ConnectorEvent.handleEvents(
      onPing: (ConnectorEvent event, EventSink<ConnectorEvent> sink) => sink.add(event),

      onPause: (ConnectorEvent event, _) {
        var subscription = subscriptions[event.id];
        if (subscription != null)
          subscription.pause();
        //print('Paused: ${event.id}');
      },

      onResume: (ConnectorEvent event, _) {
        var subscription = subscriptions[event.id];
        if (subscription != null)
          subscription.resume();
        //print('Resumed: ${event.id}');
      },

      onCancel: (ConnectorEvent event, _) {
        var subscription = subscriptions[event.id];
        if (subscription != null)
          subscription.cancel();
        subscriptions.remove(event.id);
        //print('Canceled: ${event.id}');
      },

      onCall: (ConnectorEvent event, EventSink<ConnectorEvent> sink) {
        final result = handlers[event.event](event.payload);

        Stream convertToStream(input) {;
          if (input is Stream) return input;
          else if (input is Future) { // Recursively deal with futures. For example, Future<Stream> is converted to Stream
            var controller = new StreamController();
            input.then((completion) => convertToStream(completion).pipe(controller));
            return controller.stream;
          }
          else return new Future.sync(() => input).asStream();
        }

        subscriptions[event.id] = convertToStream(result)
          .map((result) => new ConnectorEvent.fromEvent(event, type: ConnectorEvent.EVENT, payload: result))
          .listen((event) {
            if (ws.readyState == WebSocket.OPEN) {
              sink.add(event);
            } else {
              subscriptions[event.id].cancel();
            }
          })
        ..asFuture()
          .then((_) => sink.add(new ConnectorEvent.fromEvent(event, type: ConnectorEvent.END)))
          .catchError((e) => sink.add(new ConnectorEvent.fromEvent(event, type: ConnectorEvent.ERROR, payload: e is String ? e : e is Error ? e.stackTrace.toString() : null)))
          .whenComplete(() {
            subscriptions.remove(event.id);
            //sink.close();
            print('Complete');
          });
      }
    ))
    .transform(CONNECTOREVENT.encoder)
    .pipe(ws);
  
}
