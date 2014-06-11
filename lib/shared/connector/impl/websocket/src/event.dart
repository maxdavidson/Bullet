library bullet.connector.websocket.event;

import 'dart:convert' show JSON;
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:jwt/base64url.dart';

String _randomString([int length = 10])
  => BASE64URL.encode(new Iterable.generate(length, (n) => new Random().nextInt(255)).toList());

class PubSub {
  final handlers = new Map<dynamic, Set<Function>>();
  void on(value, Function fn) {
    if (handlers[value] == null) handlers[value] = new Set<Function>();
    handlers[value].add(fn);
  }
  callFn(args) => (Function fn) => Function.apply(fn, args);
  void trigger(topic, [Iterable args = const []]) =>
    handlers.forEach((key, fns) {
      if (key == topic) {
        try {
          fns.forEach(callFn(args));
        } catch (e) {
          throw 'Failed to execute handler for $topic';
        }
      }
    });
}

class ConnectorEvent {

  static const EVENT   = 'EVENT';//0;
  static const CALL    = 'CALL';//1;
  static const CANCEL  = 'CANCEL';//2;
  static const ERROR   = 'ERROR';//3;
  static const PAUSE   = 'PAUSE';//4;
  static const RESUME  = 'RESUME';//5;
  static const END     = 'END';//6;
  static const PING    = 'PING';//7;

  final type;
  final String id, event;
  final List args;
  final Map kvargs;

  ConnectorEvent(this.type, {String id, this.event, this.args: const [], this.kvargs: const {}, bool generateId: true})
    : this.id = (id == null && generateId) ? _randomString() : id;

  ConnectorEvent.fromEvent(ConnectorEvent otherEvent, {type, this.args: const [], this.kvargs: const {}})
    : event = otherEvent.event, id = otherEvent.id,
      this.type = (type != null) ? type : otherEvent.type;

  ConnectorEvent.fromJson(List obj)
    : type = obj[0], id = obj[1], event = obj[2], args = obj[3], kvargs = obj[4];

  Object toJson() => [type, id, event, args, kvargs];

}

const ConnectorEventCodec CONNECTOREVENT = const ConnectorEventCodec();

class ConnectorEventCodec extends Codec<ConnectorEvent, String> {
  const ConnectorEventCodec();
  Converter<ConnectorEvent, String> get encoder => new ConnectorEventEncoder();
  Converter<String, ConnectorEvent> get decoder => new ConnectorEventDecoder();
}

class ConnectorEventEncoder extends Converter<ConnectorEvent, String> {
  String convert(ConnectorEvent input) {
    var json = input.toJson();
    return JSON.encode(json);
  }

  ChunkedConversionSink<ConnectorEvent> startChunkedConversion(sink) =>
    new _ConnectorEncoderSink(sink);
}

class ConnectorEventDecoder extends Converter<String, ConnectorEvent> {
  ConnectorEvent convert(String input) {
    var json = JSON.decode(input);
    return new ConnectorEvent.fromJson(json);
  }

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