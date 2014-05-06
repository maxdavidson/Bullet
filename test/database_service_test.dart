import 'package:unittest/unittest.dart';
import 'package:bullet/common/database/database.dart';

void main() {
  DatabaseService db;

  setUp(() {
    db = new MockDatabaseService(null)
      ..data = {
        'ads': [{
            MockDatabaseService.ID: 0, 'title': 'Begagnade blojor', 'price': 50, 'currency': 'SEK'
        }, {
            MockDatabaseService.ID: 1, 'title': 'Gamla grejer', 'price': 75, 'currency': 'SEK'
        }]
    };
  });
  
  tearDown(() => db = null);

  test('Querying all items', () =>
    expect(
      db.find('ads').toList(),
      completion(hasLength(2))
    ));

  test('Finding a single item', () =>
    expect(
      db.find('ads', criteria: { 'price': 50 }).first,
      completion(containsPair('price', 50))));

  test('Inserting a single item', () =>
    expect(
      db.insert('ads', { 'title': 'New ad' })
        .then((_) => db.find('ads', criteria: { 'title': 'New ad' }).toList()),
        
      completion(hasLength(1))));
  
  test('Deleting a single item', () =>
    expect(
      db.find('ads', criteria: { 'price': 50 }).first
        .then((Map map) => db.delete('ads', map)),
      completion(isTrue)));
  
}
