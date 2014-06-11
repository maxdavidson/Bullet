library bullet.connector.websocket.client;

import 'dart:html';
import 'dart:async';

import 'package:quiver/async.dart';

import 'package:bullet/shared/connector/connector.dart';
export 'package:bullet/shared/connector/connector.dart';

import 'src/event.dart';


/**
 * Provides a way for a client to run remote procedures over a WebSocket connection
 */
class WebSocketConnectorClient implements ConnectorClient {

  WebSocket _ws;

  String host;
  String pathname;

  StreamRouter<ConnectorEvent> input;
  StreamController<ConnectorEvent> output;

  // Lazily connect when needed, or create a new connection if dead
  WebSocket get ws {
    if (_ws == null || _ws.readyState == WebSocket.CLOSED || _ws.readyState == WebSocket.CLOSING) {
      _ws = new WebSocket('ws://$host/$pathname');
      _initInput();
    }
    return _ws;
  }

  Future get onOpen => (ws.readyState == WebSocket.OPEN) ? new Future.microtask(() => null) : ws.onOpen.first;

  void _initInput() {
    input = new StreamRouter<ConnectorEvent>(
      ws.onMessage
         .map((MessageEvent event) => event.data)
         //.map((json) { print('Received: $json'); return json; })
         .transform(CONNECTOREVENT.decoder));
  }

  WebSocketConnectorClient({this.host, this.pathname: 'ws'}) {

    if (host == null) host = window.location.host;

    _initInput();

     // Everything added to the output stream is serialized and piped through websocket
    output = new StreamController<ConnectorEvent>()
      ..stream
        .transform(CONNECTOREVENT.encoder)
        //.map((json) { print('Sent: $json'); return json; })
        .asyncMap((data) => onOpen.then((_) => data))
        .forEach((data) => ws.send(data));
  }

  /**
   * Calls the remote procedure [identifier] with the optional data [data].
   * Returns a stream of the JSON-parsed result.
   */
  Stream subscribe(String identifier, [List args, Map kvargs]) {
    var request = new ConnectorEvent(ConnectorEvent.CALL, event: identifier, args: args, kvargs: kvargs);
    bool lock = false;

    var controller = new StreamController<dynamic>(
      onListen: () => output.add(request),
      onPause:  () => output.add(new ConnectorEvent(ConnectorEvent.PAUSE, id: request.id)),
      onResume: () => output.add(new ConnectorEvent(ConnectorEvent.RESUME, id: request.id)),
      onCancel: () { if (lock) lock = false; else output.add(new ConnectorEvent(ConnectorEvent.CANCEL, id: request.id)); }
    );

    var pubsub = new PubSub()
      ..on(ConnectorEvent.EVENT, (event, sink) => sink.add(event.args[0]))
      ..on(ConnectorEvent.ERROR, (event, sink) => sink.addError(event.args[0]))
      ..on(ConnectorEvent.END, (event, sink) { sink.close(); lock = true; });
    
    input
      .route((response) => response.id == request.id)
      .transform(new StreamTransformer<ConnectorEvent, dynamic>.fromHandlers(
        handleData: (ConnectorEvent event, EventSink<ConnectorEvent> sink) =>
          pubsub.trigger(event.type, [event, sink])))
      .pipe(controller);

    return controller.stream;
  }


  /**
   * Ping the server.
   */
  Future<Duration> ping({Duration timeout: const Duration(seconds: 10)}) {
    var stopwatch = new Stopwatch()..start();
    output.add(new ConnectorEvent(ConnectorEvent.PING, generateId: false));
    return input
      .route((event) => event.type == ConnectorEvent.PING)
      .timeout(timeout)
      .first
      .then((_) { stopwatch.stop(); return stopwatch.elapsed; });
  }

}
