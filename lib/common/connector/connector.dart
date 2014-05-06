library bullet.connector;

import 'dart:async';

/**
 * Defines a way to run remote procedures defined on a server
 */
abstract class ConnectorClient {
  Future<dynamic> remoteCall(String identifier, [data]);
  Stream<dynamic> remoteStream(String identifier, [data]);
}

/**
 * Defines a class that handles remote procedures
 */
abstract class ConnectorServer {
  void setHandler(String identifier, dynamic handler(dynamic));
  void removeHandler(String identifier);
}
