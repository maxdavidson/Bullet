library bullet.connector.websocket_client;

import 'dart:html';
import 'dart:async';

import '../../connector.dart';
import 'src/event.dart';

export '../../connector.dart';

/**
 * Provides a way for a client to run remote procedures over a WebSocket connection
 */
class WebSocketConnectorClient implements ConnectorClient {

  WebSocket _ws;
  Future _whenSocketIsOpen;
  Stream<WscEvent> _inputStream;
  StreamController<WscEvent> _outputStream;

  Stream<WscEvent> get inputStream => _inputStream;
  
  WebSocketConnectorClient({String host: 'localhost', String pathname: 'ws', int port: 80}) {
    
    _ws = new WebSocket('ws://$host:$port/$pathname');
    
    _whenSocketIsOpen = (_ws.readyState == WebSocket.OPEN)
      ? new Future.value()
      :_ws.onOpen.first.timeout(const Duration(seconds: 10));

    // _ws.onMessage.listen((e) => window.console.log('Received: ${e.data}'));
    
    _inputStream = _ws.onMessage
      .map((MessageEvent event) => event.data)
      .transform(WscEvent.decoder)
      .asBroadcastStream();
    
    _outputStream = new StreamController<WscEvent>()
      ..stream
        .transform(WscEvent.encoder)
        .listen((String json) => _whenSocketIsOpen.then((_) => _ws.send(json)));
      
    // Quick fix, not good enough
    window.onBeforeUnload.first.then((_) => _ws.close());
  }

  /**
   * Calls the remote procedure [identifier] with the optional data [data].
   * Returns a stream of the JSON-parsed result.
   */
  Stream<dynamic> remoteStream(String identifier, [data]) {
    
    var request = new WscEvent(WscEvent.CALL, event: identifier, payload: data);
    
    // Handle subscription events
    var controller = new StreamController(
      onCancel: () => _outputStream.add(new WscEvent(WscEvent.CANCEL, id: request.id)),
      onPause:  () => _outputStream.add(new WscEvent(WscEvent.PAUSE, id: request.id)),
      onResume: () => _outputStream.add(new WscEvent(WscEvent.RESUME, id: request.id))
    );

    _inputStream
      .where((response) => response.id == request.id)
      .transform(WscEvent.handleEvents(
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
    _outputStream.add(new WscEvent(WscEvent.PING, generateId: false));
    return _inputStream
      .asBroadcastStream()
      .firstWhere((event) => event.type == WscEvent.PING)
      .timeout(timeout)
      .then((_) { stopwatch.stop(); return stopwatch.elapsed; });
  }

}
