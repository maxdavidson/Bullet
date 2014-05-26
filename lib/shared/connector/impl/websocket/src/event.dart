library bullet.connector.websocket.event;

import 'dart:convert' show JSON;
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:jwt/base64url.dart';

String _randomString([int length = 10])
  => BASE64URL.encode(new Iterable.generate(length, (n) => new Random().nextInt(255)).toList());

class ConnectorEvent {

  static const EVENT   = 0;
  static const CALL    = 1;
  static const CANCEL  = 2;
  static const ERROR   = 3;
  static const PAUSE   = 4;
  static const RESUME  = 5;
  static const END     = 6;
  static const PING    = 7;

  static StreamTransformer<ConnectorEvent, ConnectorEvent> handleEvents(
      {onEvent, onCall, onCancel, onError, onPause, onResume, onEnd, onPing})
    => new StreamTransformer.fromHandlers(
      handleData: (ConnectorEvent event, EventSink<ConnectorEvent> sink) {
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
          print(e);
          //sink.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.ERROR, id: event.id, event: event.event));
        }
      });

  String _id;
  int type;
  String event;
  Object payload;

  String get id => _id;

  ConnectorEvent(this.type, {this.event, this.payload, id, bool generateId: true})
    : _id = (id == null && generateId) ? _randomString() : id;

  ConnectorEvent.fromEvent(ConnectorEvent otherEvent, {int type, this.payload})
    : event = otherEvent.event, _id = otherEvent.id,
      this.type = (type != null) ? type : otherEvent.type;

  /**
   * Defines how event objects are deserialized
   */
  ConnectorEvent.fromJson(Object json) {
    var obj = json as List;
    this
      ..type = obj[0]
      ..event = obj[1]
      ..payload = obj[3]
      .._id = obj[2];
  }

  /**
   * Defines how event objects are serialized.
   */
  Object toJson() => [type, event, id, payload];

}

const ConnectorEventCodec CONNECTOREVENT = const ConnectorEventCodec();

class ConnectorEventCodec extends Codec<ConnectorEvent, String> {
  const ConnectorEventCodec();
  Converter<ConnectorEvent, String> get encoder => new ConnectorEventEncoder();
  Converter<String, ConnectorEvent> get decoder => new ConnectorEventDecoder();
}

class ConnectorEventEncoder extends Converter<ConnectorEvent, String> {
  String convert(ConnectorEvent input) =>
    JSON.encode(input.toJson());

  ChunkedConversionSink<ConnectorEvent> startChunkedConversion(sink) =>
    new _ConnectorEncoderSink(sink);
}

class ConnectorEventDecoder extends Converter<String, ConnectorEvent> {
  ConnectorEvent convert(String input) =>
    new ConnectorEvent.fromJson(JSON.decode(input));

  ChunkedConversionSink<String> startChunkedConversion(sink) =>
    new _ConnectorDecoderSink(sink);
}

class _ConnectorEncoderSink extends ChunkedConversionSink<ConnectorEvent> {
  final _converter = new ConnectorEventEncoder();
  final Sink<ConnectorEvent> _outSink;

  _ConnectorEncoderSink(this._outSink);

  void add(ConnectorEvent data) => _outSink.add(_converter.convert(data));
  void close() => _outSink.close();
}

class _ConnectorDecoderSink extends ChunkedConversionSink<String> {
  final _converter = new ConnectorEventDecoder();
  final Sink<String> _outSink;

  _ConnectorDecoderSink(this._outSink);

  void add(String data) => _outSink.add(_converter.convert(data));
  void close() => _outSink.close();
}