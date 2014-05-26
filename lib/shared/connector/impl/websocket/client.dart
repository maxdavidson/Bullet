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

  Future get onOpen =>
    (ws.readyState == WebSocket.OPEN)
      ? new Future.sync(() => null)
      : ws.onOpen.first;

  void _initInput() {
    input = new StreamRouter<ConnectorEvent>(
      ws.onMessage
         .map((MessageEvent event) => event.data)
         .transform(CONNECTOREVENT.decoder));
  }

  WebSocketConnectorClient({this.host, this.pathname: 'ws'}) {

    if (host == null) host = window.location.host;

    _initInput();

     // Everything added to the output stream is serialized and piped through websocket
    output = new StreamController<ConnectorEvent>()
      ..stream
        .transform(CONNECTOREVENT.encoder)
        .forEach((data) => onOpen.then((_) => ws.send(data)));
  }

  /**
   * Calls the remote procedure [identifier] with the optional data [data].
   * Returns a stream of the JSON-parsed result.
   */
  Stream subscribe(String identifier, [data]) {
    var request = new ConnectorEvent(ConnectorEvent.CALL, event: identifier, payload: data);
    bool lock = false;

    var controller = new StreamController(
      onListen: () => output.add(request),
      onCancel: () {
        if (lock) 
          lock = false;
        else 
          output.add(new ConnectorEvent(ConnectorEvent.CANCEL, id: request.id));
      },
      onPause:  () => output.add(new ConnectorEvent(ConnectorEvent.PAUSE, id: request.id)),
      onResume: () => output.add(new ConnectorEvent(ConnectorEvent.RESUME, id: request.id))
    );

    input
      .route((response) => response.id == request.id)
      .transform(ConnectorEvent.handleEvents(
        onError: (event, sink) { controller.addError(event.payload); },
        onEnd:   (event, sink) { controller.close(); lock = true; },
        onEvent: (event, sink) { controller.add(event.payload); }
      ))
      .drain();

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
