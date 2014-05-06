library bullet.connector.websocket.event;

import 'dart:convert' show JSON;
import 'dart:math';
import 'dart:async';

String _randomString([int length = 10]) {
  var buffer = new StringBuffer();
  var random = new Random();
  int a = 'a'.codeUnitAt(0);
  for (int i = 0; i < length; i++)
    buffer.writeCharCode(random.nextInt(26) + a);
  return buffer.toString();
}

class WscEvent {

  static const EVENT   = 0;
  static const CALL    = 1;
  static const CANCEL  = 2;
  static const ERROR   = 3;
  static const PAUSE   = 4;
  static const RESUME  = 5;
  static const END     = 6;
  static const PING    = 7;

  static final StreamTransformer<String, WscEvent> decoder = new StreamTransformer.fromHandlers(
    handleData: (String input, EventSink<WscEvent> sink) {
      print('Recieved: $input');
      sink.add(new WscEvent.fromJson(input));
    });

  static final StreamTransformer<WscEvent, String> encoder = new StreamTransformer.fromHandlers(
    handleData: (WscEvent input, EventSink<String> sink) {
      print('Sent: ${input.toJson()}');
      sink.add(input.toJson());
    });

  static StreamTransformer<WscEvent, WscEvent> handleEvents(
      {onEvent, onCall, onCancel, onError, onPause, onResume, onEnd, onPing})
    => new StreamTransformer.fromHandlers(
      handleData: (WscEvent event, EventSink<WscEvent> sink) {
        final Map<int, Function> handlers = {
          EVENT: onEvent,
          CALL: onCall,
          CANCEL: onCancel,
          ERROR: onError,
          PAUSE: onPause,
          RESUME: onResume,
          END: onEnd,
          PING: onPing
        };

        try {
          var handler = handlers[event.type];
          if (handler != null) handler(event, sink);
        } catch (e) {
          //sink.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.ERROR, id: event.id, event: event.event));
        }
      });

  String _id;
  int type;
  String event;
  var payload;

  String get id => _id;

  WscEvent(int this.type, {String this.event, this.payload, String id, bool generateId: true})
    : _id = (id == null && generateId) ? _randomString() : id;

  WscEvent.fromJson(String json) {
    final obj = JSON.decode(json);
    this
      ..type = obj[0]
      ..event = obj[1]
      ..payload = obj[3]
      .._id = obj[2];
  }

  String toJson() => JSON.encode([type, event, id, payload]);

}
