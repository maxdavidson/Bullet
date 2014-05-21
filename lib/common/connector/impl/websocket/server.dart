library bullet.connector.websocket_server;

import 'dart:io';
import 'dart:async';

import '../../connector.dart';
import 'src/event.dart';

export '../../connector.dart';

/**
 * Defines a class that handles remote procedures
 */
class WebSocketConnectorServer implements ConnectorServer<WebSocket> {

  final _subscriptions = new Map<String, StreamSubscription>();
  final _handlers = new Map<String, Function>();

  @override
  void bind(String identifier, handler(dynamic)) { _handlers[identifier] = handler; }

  @override
  void unbind(String identifier) { _handlers.remove(identifier); }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) => null;

  @override
  void close() => null;

  Future addStream(Stream<WebSocket> stream) => stream.forEach(add);
  Future cancel() => Future.wait(_subscriptions.values.map((sub) => sub.cancel()));

  @override
  add(WebSocket ws) => ws
    .transform(WscEvent.decoder)
    .transform(WscEvent.handleEvents(
      onPing: (event, sink) => sink.add(event),

      onPause: (event, _) {
        _subscriptions[event.id].pause();
        print('Paused: ${event.id}');
      },

      onResume: (event, _) {
        _subscriptions[event.id].resume();
        print('Resumed: ${event.id}');
      },

      onCancel: (event, _) {
        _subscriptions[event.id].cancel();
        _subscriptions.remove(event.id);
        print('Canceled: ${event.id}');
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
            .listen((event) => (ws.readyState != WebSocket.OPEN) ? _subscriptions[event.id].cancel() : sink.add(event),
              onDone:  () => sink.add(new WscEvent(WscEvent.END, id: event.id, event: event.event)),
              onError: (Error e) => sink.add(new WscEvent(WscEvent.ERROR, id: event.id, event: event.event, payload: e.stackTrace.toString()))
            );
        } catch (_) { 
          sink.add(new WscEvent(WscEvent.ERROR, id: event.id, event: event.event));
          print('Error: ${event.id}');
        } finally {
          print('Started: ${event.id}');
        }
      }
    ))
    .transform(WscEvent.encoder)
    .pipe(ws);
  
}
