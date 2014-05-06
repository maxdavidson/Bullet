library bullet.connector.websocket_server;

import 'dart:io';
import 'dart:async';

import '../../connector.dart';
import 'src/event.dart';

export '../../connector.dart';

/**
 * Defines a class that handles remote procedures
 */
class WebSocketConnectorServer implements ConnectorServer, StreamConsumer<WebSocket> {

  Map<String, StreamSubscription> _subscriptions = new Map<String, StreamSubscription>();
  Map<String, Function> _handlers = new Map<String, Function>();

  void setHandler(String identifier, handler(dynamic)) { _handlers[identifier] = handler; }
  void removeHandler(String identifier) { _handlers.remove(identifier); }

  Future addStream(Stream<WebSocket> stream) => stream.forEach(handler);
  Future close() => new Future.value(); // todo

  handler(WebSocket ws) => ws
    .transform(WscEvent.decoder)
    .transform(WscEvent.handleEvents(
      onPing: (event, sink) => sink.add(event),
      
      onPause: (event, _) => _subscriptions[event.id].pause(),
      onResume: (event, _) => _subscriptions[event.id].resume(),
      onCancel: (event, _) {
        _subscriptions[event.id].cancel();
        _subscriptions.remove(event.id);
      },

      onCall: (event, sink) {
        try { 
          final result = _handlers[event.event](event.payload);
          
          Stream convertToStream(input) {;
            if (input is Stream) return input;
            else if (input is Future) { // Recursively deal with futures. For example, Future<Stream> is converted to Stream
              final controller = new StreamController();
              input.then((completion) => convertToStream(completion).pipe(controller));
              return controller.stream;
            }
            else return new Future.value(input).asStream();
          }
          
          _subscriptions[event.id] = convertToStream(result)
            .map((result) => new WscEvent(WscEvent.EVENT, payload: result, id: event.id, event: event.event))
            .listen((event) => sink.add(event),
              onDone:  () => sink.add(new WscEvent(WscEvent.END, id: event.id, event: event.event)),
              onError: (_) => sink.add(new WscEvent(WscEvent.ERROR, id: event.id, event: event.event))
            );
        } catch (_) { 
          sink.add(new WscEvent(WscEvent.ERROR, id: event.id, event: event.event));
        }

      }
    ))
    .transform(WscEvent.encoder)
    .pipe(ws);
  
}
