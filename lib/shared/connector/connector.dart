library bullet.connector;

import 'dart:async';


/**
 * Defines a way to subscribe to event streams defined somewhere else.
 */
abstract class ConnectorClient {
  /**
   * Subscribes to the behavior defined by [identifier].
   * Can be used for remote procedure call, since streams may end
   */
  Stream subscribe(String identifier, [List args, Map kwargs]);
}

/**
 * Defines a class that handles reactions to specific identifiers.
 * Reaction functions must have only  one parameter,
 * since this is a limitation of Dart. (No varargs)
 */
abstract class ConnectorServer<T extends Stream> extends EventSink<T> {
  /**
   * Bind a behavior for a specific identifier.
   * The handler may return void or a stream, a future,
   * or a value of a serializable object.
   */
  void bind(String identifier, Function handler);

  /**
   * Unbind the behavior for a specific identifier.
   */
  void unbind(String identifier);
}
