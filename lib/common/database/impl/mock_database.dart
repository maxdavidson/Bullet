part of bullet.common.database;

@Injectable()
class MockDatabaseService implements DatabaseService {

  static final String ID = '_id';

  Map<String, List<Map>> data = {
      'ads': [
          { ID: 0, 'title': 'Begagnade blöjor', 'price': 50, 'date': new DateTime.utc(2014, 5, 3).toString() },
          { ID: 1, 'title': 'Gamla grejer', 'price': 75, 'date': '2014-04-01 12:00' }
      ]
  };

  AuthenticationService authentication;

  MockDatabaseService(this.authentication);

  Stream<Map> find(String collection, {Map criteria, bool live: false, metaData}) {
    if (!data.containsKey(collection)) throw new Exception('No such collection');
    Iterable result = (criteria is Map)
      ? data[collection].where((Map object) => criteria.keys.every((key) => criteria[key] == object[key]))
      : data[collection];
    return new Stream.fromIterable(result);
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
