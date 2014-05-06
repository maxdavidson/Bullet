part of bullet.common.database;

/**
 * Represents an instance of an item in a [Collection].
 * The internal state may be automatically updated by the [Collection].
 */
abstract class Model implements StreamConsumer<Map> {

  Collection collection;
  Map _state = {};
  Map get state => _state;
  
  Model({this.collection});

  int get id => _state['_id'];

  void update(Map update) =>
    update.keys.forEach((key) => _state[key] = update[key]);

  Future addStream(Stream<Map> updateStream) => updateStream.forEach(update);
  Future close() => new Future.value(); // TODO

  /**
   * Persists the [Model]'s state to the database.
   * If successful, the future completes. Otherwise, it throws.
   */
  Future save() {
    // TODO
  }

}

typedef T ModelBuilder<T>();

/**
 * Represents a table or collection in a database. Should be subclassed for specific tables.
 * A simple ORM that returns [Model] objects whose state can be saved to the database.
 */
abstract class Collection<T extends Model> {

  String collectionName; // Needs to be set

  DatabaseService db;

  // Need this to define how to instantiate [Model] objects, since generics are optional and require
  // reflection to use creatively, since classes are not first-class objects in Dart. Can't do new T();
  ModelBuilder<T> _builder;

  StreamController<Map> _controller = new StreamController<Map>();
  Stream<Map> _stream;

  Collection(this.collectionName, this.db, this._builder) {
    _stream = _controller.stream.asBroadcastStream();
  }

  /**
   * Queries the [Collection] and a returns an asynchronous stream of result models.
   * The [selector] map follows MongoDb syntax.
   * If [live] is true, then the stream will stay alive and broadcast any new matches.
   * Otherwise, the stream ends when no more entries are found.
   */
  Stream<T> find({Map criteria, bool live: true}) {
    db.find(collectionName, criteria: criteria, live: live).pipe(_controller);
    return _stream
      .distinct((Map prev, Map next) => prev['_id'] == next['_id'])
      .map((Map map) {
        var model = _builder() // new T();
          ..update(map)
          ..collection = this;
        _stream
          .where((Map update) => update['_id'] == map['_id'])
          .distinct((Map prev, Map next) => prev['_id'] == next['_id'])
          .pipe(model);
        return model;
      });
  }

  /**
   * Creates a new [Model] and saves .
   * If successful, the model gets an id. Otherwise, it throws.
   */
  Future<T> create(T model) {
    // TODO
  }

}
