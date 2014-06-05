import 'package:unittest/unittest.dart';
import 'package:bullet/common/database/impl/mock.dart';
import 'package:bullet/common/database/mapper.dart';

class Person extends Entity {
  String get name => value['name'];
  int get age => value['age'];

  set name(val) => value['name'] = val;
  set age(val) => value['age'] = val;
}

class PersonMapper extends EntityMapper<Person> {
  PersonMapper(Database db) : super('people', db, builder: () => new Person());
}

void main() {

  group('Entities', () {
    StreamController<Map> controller;
    Person person;

    setUp(() {
      controller = new StreamController<Map>();
      person = new Person()
        ..id = 0
        ..name = 'Max'
        ..age = 24
        ..addStream(controller.stream);
    });

    tearDown(() => controller = null);

    test('Basic deserialization', () {
      person.update({ 'name': 'Martin', 'age': 25 });
      expect(person.name, equals('Martin'));
      expect(person.age, equals(25));
    });

    test('Prevent deserizalizing with wrong ID', () {
      expect(() => person.update({ '_id': 2 }), throws);
    });

    test('Updating through update stream', () {
      controller.add({ 'name': 'Martin', 'age': 25 });
      return person.onUpdate.first
        .then((_) {
          expect(person.name, equals('Martin'));
          expect(person.age, equals(25));
        });
    });

    test('Serializing only inherited parameters', () {
      expect(person.toJson(onlyInherited: true), equals({ 'name': 'Max', 'age': 24 }));
    });

    test('Serializing all parameters', () {
      var map = person.toJson();
      expect(map, containsPair(person.idField, 0));
    });

    test('Deserializing and parse date', () {
      var beforeUpdate = new DateTime.now();
      person.update({ 'age': 40 });
      expect(person.lastUpdated, isNotNull);
      expect(person.lastUpdated, new isInstanceOf<DateTime>());
      expect(beforeUpdate.compareTo(person.lastUpdated) <= 0, isTrue);
    });

    test('Many updates through stream', () {
      var ages = [19, 56, 95, 23, 45], n = 0;
      ages.map((age) => { 'age' : age }).forEach(controller.add);

      return person.onUpdate
        .take(ages.length)
        .listen((_) => expect(person.age, equals(ages[n++])))
        .asFuture();
    });

    test('Switching update streams', () {
      var controller2 = new StreamController();
      var n = 0;

      // First action
      controller.add({ 'age': 102 });
      // Update response actions
      var actions = <Function> [
        () {
          expect(person.age, equals(102));
          controller.add({ 'age': 105 });
        },
        () {
          expect(person.age, equals(105));
          controller2.stream.pipe(person);
          controller2.add({ 'age': 19 });
        },
        () {
          expect(person.age, equals(19));
        }
      ];

      return person.onUpdate
        .take(actions.length)
        .map((_) => person.age)
        .listen((age) => actions[n++]())
        .asFuture()
        .timeout(const Duration(seconds: 3), onTimeout: () => fail('Timeout reached'));
    });

  });

  group('MockDatabaseService', () {
    Database db;

    setUp(() => db = new MockDatabaseService(null)..data = {
      'people': [
        { MockDatabaseService.ID: 0, 'name': 'Max', 'age': 24 },
        { MockDatabaseService.ID: 1, 'name': 'Martin', 'age': 25 },
        { MockDatabaseService.ID: 2, 'name': 'Otto', 'age': 25 },
        { MockDatabaseService.ID: 3, 'name': 'Päron', 'age': 25 },
      ]
    });

    tearDown(() => db = null);

    test('Querying all items', () =>
      db.find('people').toList()
        .then((List<Map> result) => expect(result, hasLength(4))));

    test('Querying with a projection', () =>
      db.find('people', projection: ['age'])
        .listen((Map result) => expect(result.keys, allOf(hasLength(1), contains('age'))))
        .asFuture());

    test('Finding a single item', () =>
      db.find('people', query: { 'age': 24 }).first
        .then((Map result) => expect(result, containsPair('age', 24))));

    test('Inserting a single item', () =>
      db.insert('people', { 'name': 'David' })
        .then((_) => db.find('people', query: { 'name': 'David' }).first)
        .then((Map result) => expect(result, containsPair('name', 'David'))));

    test('Deleting a single item', () =>
      db.find('people', query: { 'age': 24 }, live: false).first
        .then((Map map) => db.delete('people', map))
        .then((bool success) => expect(success, isTrue)));

    group('EntityMapper', () {
      EntityMapper<Person> people;

      setUp(() => people = new UserMapper(db));
      tearDown(() => people = null);

      test('Cancelling stream right away', () =>
        people.find().take(1).toList()
          .then((List list) => expect(list, hasLength(1))));

      test('Fetching all items', () =>
        people.find(live: false).toList()
          .then((list) {
            expect(list, hasLength(4));
            list.forEach((Person person) => expect(person.name, isNotNull));
          }));

      test('Fetching a single model', () =>
        people.find(query: { 'name': 'Max' }).first
          .then((person) {
            expect(person.name, equals('Max'));
          }));

    });
  });

}