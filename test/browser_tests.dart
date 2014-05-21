import 'dart:async';
import 'dart:math';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'package:bullet/common/connector/impl/websocket/client.dart';

void main() {
  useHtmlEnhancedConfiguration();

  group('WebsocketConnector', () {
    var connector = new WebSocketConnectorClient(pathname: 'api', port: 1234);

    test('Ping response', () => expect(connector.ping(), completes));

    test('Remote procedure call without data', () {
      expect(connector.subscribe('delayed').first, completion(equals('hello')));
    });

    test('Remote procedure call with data', () {
      expect(connector.subscribe('sum', [1, 2, 3, 4, 5]).first, completion(equals(15)));
    });

    test('Multiple asynchronous procedure calls', () {
      checkResponse(value) => (response) {
        if (response != value) return new Future.error(null);
        else return new Future.value(null);
      };

      var futures = [];
      for (int i = 0; i < 50; i++) {
        var rand = new Random().nextInt(50000);
        futures.add(connector.subscribe('hello', rand).first.then(checkResponse(rand)));
      }

      expect(Future.wait(futures), completes);
    });

    test('Improperly set handler on server throws', () {
      expect(connector.subscribe('fail').first, throws);
    });

    test('Remote stream returns in correct order', () {
      expect(connector.subscribe('stream', [1,2,3,4]).toList(), completion(equals([1,2,3,4])));
    });

    test('Sending improper data throws', () {
      expect(connector.subscribe('stream', 8).first, throws);
    });
    
    test('Pausing/resuming/canceling remote stream', () {
      var completer = new Completer();
      var sub = connector.subscribe('timer').listen(null);
      sub.onData((int i) { 
        if (i == 5) {
          sub.pause();
          new Future.delayed(const Duration(seconds: 2))
            .then((_) => sub.resume());
        } 
        else if (i == 6) {
          completer.complete();
          sub.cancel();
        }
      });
      expect(completer.future, completes);
    });
   
  });
}