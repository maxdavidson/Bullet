library bullet.database.mock;

import 'dart:async';
import 'dart:math';
import 'package:stream_ext/stream_ext.dart';
import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';

class MockDatabase implements Database {

  static final String ID = '_id';

  static Map<String, List<Map>> data = {
    'ads': [
      { ID: 0, 'title': 'En gammal byrå', 'price': 50 },
      { ID: 1, 'title': 'Två stora bananer säljes!', 'price': 500 },
      { ID: 2, 'title': 'Pajaskokos!', 'price': 13 },
      { ID: 3, 'title': 'Ät mina kortbyxor!', 'price': 399 },
      { ID: 4, 'title': 'Äppelkaka!!', 'price': 56 },
      { ID: 5, 'title': 'Kanin', 'price': 25 },
      { ID: 6, 'title': 'Kokos', 'price': 25 },
      { ID: 7, 'title': 'Ananas!!', 'price': 25 },
      { ID: 8, 'title': 'Köp varm korv', 'price': 25 },
    ]
  };

  final updateController = new StreamController<Map>.broadcast()
/*    ..addStream(StreamExt.repeat(new Stream<Map>.fromIterable(data['ads']))
        .asyncMap((Map map) => new Future.delayed(new Duration(milliseconds: new Random().nextInt(250)), () => map))
        .map((Map map) => map..['price'] = new Random().nextInt(1000)));
*/
      ..addStream(new Stream.periodic(const Duration(milliseconds: 100))
        .map((_) => new Random().nextInt(data['ads'].length-1))
        .map((id) => data['ads'].firstWhere((Map map) => map[ID] == id))
        .map((Map map) => map..['price'] = new Random().nextInt(1000)));

  Authenticator authenticator;

  MockDatabase(this.authenticator);

  Stream<Map> find(String collection, {Map<String, dynamic> query, List<String> fields, Map<String, int> orderBy, int limit, int skip, bool live: false, Object metadata}) {
    if (!data.containsKey(collection)) throw new Exception('No such collection');

    bool criteriaTest(Map object) {
      if (query == null) return true;
      return query.keys.every((key) {
        var target = object[key];
        var value = query[key];
        if (target is String)
          return target.toLowerCase().contains(value.toString().toLowerCase());
        else return target == value;
      });
    }

    Map project(Map object) =>
      object.keys
        .where((key) => (projection == null) || projection.contains(key))
        .fold({}, (newObject, key) => newObject..[key] = object[key]);

    var stream = new Stream<Map>.fromIterable(data[collection].where(criteriaTest).map(project));

    if (live) stream = StreamExt.concat(stream, updateController.stream.where(criteriaTest).map(project));

    return stream;
  }

  Future<Map> insert(String collection, Map object, {metaData}) {
    if (!data.containsKey(collection)) throw new Exception('No such collection');
          
    object[ID] = 1 + data[collection].map((Map row) => row[ID]).fold(0, (a, b) => (a > b) ? a : b);
    data[collection].add(object);
    return new Future.value({ ID: object[ID] });
  }

  Future update(String collection, Map object, {metaData}) {
    if (!data.containsKey(collection)) throw new Exception('No such collection');
    
    var found = data[collection].firstWhere((Map item) => item[ID] == object[ID]);
    object.forEach((key, value) => found[key] = value);
    return new Future.value({ ID: found[ID] });
  }

  Future<bool> delete(String collection, Map object, {metaData}) {
    if (!data.containsKey(collection)) throw new Exception('No such collection');

    var exists = data[collection].where((Map item) => item[ID] == object[ID]).isNotEmpty;
    data[collection].removeWhere((Map item) => item[ID] == object[ID]);

    return new Future.value(exists);
  }

}
