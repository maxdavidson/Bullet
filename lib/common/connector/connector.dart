library bullet.connector;

import 'dart:async';


/**
 * Defines a way to run remote procedures defined on a server
 */
abstract class Connector {
  Future<dynamic> remoteCall(String identifier, [data]);
  Stream<dynamic> remoteStream(String identifier, [data]);
}
/**
 * Defines a class that handles remote procedures
 */
abstract class ConnectorServer {
  void setHandle(String identifier, dynamic handle(dynamic));
  void removeHandle(String identifier);
}
