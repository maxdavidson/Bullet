library bullet.connector.websocket_client;

import 'dart:html';
import 'dart:async';

import 'package:quiver/async.dart';

import 'package:bullet/common/connector/connector.dart';
export 'package:bullet/common/connector/connector.dart';

import 'src/event.dart';

/**
 * Provides a way for a client to run remote procedures over a WebSocket connection
 */
class WebSocketConnectorClient implements ConnectorClient {

  WebSocket ws;

  StreamRouter<WscEvent> input;
  StreamController<WscEvent> output;

  Future get onOpen =>
    (ws.readyState == WebSocket.OPEN)
      ? new Future.sync(() => null)
      : ws.onOpen.first;

  WebSocketConnectorClient({String host, String pathname: 'ws'}) {

    if (host == null) host = window.location.host;

    var message = querySelector('body');
    message.appendText(host);

    ws = new WebSocket('ws://$host/$pathname');

    ws.onMessage.map((event) => event.data).listen(message.appendText);
    ws.onOpen.map((event) => 'OPEN').listen(message.appendText);
    ws.onError.map((event) => 'ERRRO').listen(message.appendText);

    input = new StreamRouter<WscEvent>(
      ws.onMessage
        .map((MessageEvent event) => event.data)
        .transform(WscEvent.decoder));

     // Everything added to the output stream is serialized and piped through websocket
    output = new StreamController<WscEvent>()
      ..stream
        .transform(WscEvent.encoder)
        .forEach((String json) => onOpen.then((_) => ws.send(json)));
  }

  /**
   * Calls the remote procedure [identifier] with the optional data [data].
   * Returns a stream of the JSON-parsed result.
   */
  Stream subscribe(String identifier, [data]) {
    var request = new WscEvent(WscEvent.CALL, event: identifier, payload: data);
    bool lock = false;

    var controller = new StreamController(
      onListen: () => output.add(request),
      onCancel: () => lock ? lock = false : output.add(new WscEvent(WscEvent.CANCEL, id: request.id)),
      onPause:  () => output.add(new WscEvent(WscEvent.PAUSE, id: request.id)),
      onResume: () => output.add(new WscEvent(WscEvent.RESUME, id: request.id))
    );

    input
      .route((response) => response.id == request.id)
      .transform(WscEvent.handleEvents(
        onError: (event, _) => controller.addError(event.payload),
        onEnd:   (event, _) { controller.close(); lock = true; },
        onEvent: (event, _) => controller.add(event.payload)
      ))
      .drain();

    return controller.stream;
  }

  /**
   * Ping the server.
   */
  Future<Duration> ping({Duration timeout: const Duration(seconds: 10)}) {
    var stopwatch = new Stopwatch()..start();
    output.add(new WscEvent(WscEvent.PING, generateId: false));
    return input
      .route((event) => event.type == WscEvent.PING)
      .timeout(timeout)
      .first
      .then((_) { stopwatch.stop(); return stopwatch.elapsed; });
  }

}
