library bullet.connector.websocket.client;

import 'dart:html';
import 'dart:async';

import '../connector.dart';
import 'event.dart';

/**
 * Provides a way for a client to run remote procedures
 */
class WebSocketConnector implements Connector {

  WebSocket _ws;
  Future _whenSocketIsOpen;
  Stream<WebSocketConnectorEvent> _inputStream;
  StreamController<WebSocketConnectorEvent> _outputStream;

  Stream<WebSocketConnectorEvent> get inputStream => _inputStream;
  
  WebSocketConnector({String host: 'localhost', String pathname: 'ws', int port: 80}) {
    
    _ws = new WebSocket('ws://$host:$port/$pathname');
    
    _whenSocketIsOpen = (_ws.readyState == WebSocket.OPEN)
      ? new Future.value()
      :_ws.onOpen.first.timeout(const Duration(seconds: 10));

    // _ws.onMessage.listen((e) => window.console.log('Recieved: ${e.data}'));
    
    _inputStream = _ws.onMessage
      .map((MessageEvent event) => event.data)
      .transform(WebSocketConnectorEvent.decoder)
      .asBroadcastStream();
    
    _outputStream = new StreamController<WebSocketConnectorEvent>()
      ..stream
        .transform(WebSocketConnectorEvent.encoder)
        .listen((String json) => _whenSocketIsOpen.then((_) => _ws.send(json)));
      
    // Quick fix, not good enough
    window.onBeforeUnload.first.then((_) => _ws.close());
  }

  /**
   * Calls the remote procedure [identifier] with the optional data [data].
   * Returns a stream of the JSON-parsed result.
   */
  Stream<dynamic> remoteStream(String identifier, [data]) {
    
    var request = new WebSocketConnectorEvent(WebSocketConnectorEvent.CALL, event: identifier, payload: data);
    
    // Handle subscription events
    var controller = new StreamController(
      onCancel: () => _outputStream.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.CANCEL, id: request.id)),
      onPause:  () => _outputStream.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.PAUSE, id: request.id)),
      onResume: () => _outputStream.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.RESUME, id: request.id))
    );

    _inputStream
      .where((response) => response.id == request.id)
      .transform(WebSocketConnectorEvent.handleEvents(
        onError: (event, _) => controller.addError(event),
        onEnd:   (event, _) => controller.close(),
        onEvent: (event, _) => controller.add(event.payload)
      ))
      .listen(null); // Force the transformer to run
    
    _outputStream.add(request);

    return controller.stream;
  }

  /**
   * Calls a remote procedure [identifier] with optional data [data].
   * Returns a future resolving the result.
   */
  Future<dynamic> remoteCall(String identifier, [data]) => remoteStream(identifier, data).first;

  /**
   * Ping the server.
   */
  Future<Duration> ping({Duration timeout: const Duration(seconds: 10)}) {
    var stopwatch = new Stopwatch()..start();
    _outputStream.add(new WebSocketConnectorEvent(WebSocketConnectorEvent.PING, generateId: false));
    return _inputStream
      .asBroadcastStream()
      .firstWhere((event) => event.type == WebSocketConnectorEvent.PING)
      .timeout(timeout)
      .then((_) { stopwatch.stop(); return stopwatch.elapsed; });
  }

}
