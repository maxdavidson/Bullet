library bullet.connector.websocket.server;

import 'dart:io';
import 'dart:async';

import '../connector.dart';
import 'event.dart';


class WebSocketConnectorServer implements ConnectorServer, StreamConsumer<WebSocket> {

  Map<String, StreamSubscription> _subscriptions = new Map<String, StreamSubscription>();
  Map<String, Function> _handlers = new Map<String, Function>();

  void setHandle(String identifier, handle(dynamic)) { _handlers[identifier] = handle; }
  void removeHandle(String identifier) { _handlers.remove(identifier); }

  Future addStream(Stream<WebSocket> stream) => stream.forEach(handle);
  Future close() => new Future.value(); // todo

  handle(WebSocket ws) => ws
    .transform(WebSocketConnectorEvent.decoder)
    .transform(WebSocketConnectorEvent.handleEvents(
      onPing: (event, sink) => sink.add(event),
      
      onPause: (event, _) => _subscriptions[event.id].pause(),
      onResume: (event, _) => _subscriptions[event.id].resume(),
      onCancel: (event, _) {
        _subscriptions[event.id].cancel();
        _subscriptions.remove(event.id);
      },

      onCall: (event, sink) {
        try { 
          var result = _handlers[event.event](event.payload);
          
          // Transform anything into a stream of values
          Stream stream = (result is Stream) ? result : (result is Future) ? result.asStream() : new Future.value(result).asStream();

          _subscriptions[event.id] = stream
            .map((result) => new WebSocketConnectorEvent(WebSocketConnectorEvent.EVENT, payload: result, id: event.id, event: event.event))
            .listen((event) => sink.add(event),
              onDone:  () => sink.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.END, id: event.id, event: event.event)),
              onError: (_) => sink.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.ERROR, id: event.id, event: event.event))
            );
        } catch (_) { 
          sink.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.ERROR, id: event.id, event: event.event));
        }

      }
    ))
    .transform(WebSocketConnectorEvent.encoder)
    .pipe(ws);
  
}
