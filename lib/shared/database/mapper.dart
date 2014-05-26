library bullet.database.mapper;

import 'dart:async';

import 'package:bullet/shared/stream_helpers.dart';
import 'package:bullet/shared/database/database.dart';
export 'package:bullet/shared/database/database.dart';


/**
 * Represents a single object in a database.
 */
class Entity extends ReactiveProperty<Map> {

  EntityMapper mapper;

  get idField => mapper == null ? '_id' : mapper.idField;
  get id => value[idField];
  set id(val) => value[idField] = val;

  DateTime get created => value['created'];
  DateTime get updated => value['updated'];

  Entity() : super({}) {
    //this.map((me) => 'Updated ${this.id}').listen(print);
    //this.map((me) => 'Created ${this.id}').first.then(print);
  }

  /**
   * Starts subscription to update stream.
   * Returns with self on first update
   */
  Future<Entity> start() {
    mapper.rawFind(query: { idField: id }, live: true).pipe(this);
    return this.first.then((_) => this);
  }

  @override
  Future addStream(Stream<Map> stream) => super.addStream(
      stream.transform(scan(value, (Map state, Map update) {
        update.forEach((String key, val) => state[key] = val);
        state['created'] = state.containsKey('created') 
            ? DateTime.parse(state['created']) 
            : new DateTime.now();
        state['updated'] = new DateTime.now();
        return state;
      })));

  // TODO
  Future destroy() {

  }
}


/**
 * A function that returns an instance of a subclass of [Entity].
 */
typedef T EntityBuilder<T extends Entity>();


/**
 * Maps a database collection and keeps track of a set of auto-updating entities
 */
class EntityMapper<T extends Entity> {

  final Database db;
  final EntityBuilder<T> builder;

  final String collectionName;
  final String idField;

  static final cache = new Map<dynamic, Entity>();
  
  /**
   * [collectionName] is the name of database collection or table.
   * [idField] is the field that uniquely identifies an object or row, by default '_id'.
   * [db] is an instance of [Database] for querying.
   * [builder] is a function that returns an instance of an [Entity] subclass, e.g. () => new Ad(),
   * because the only way to otherwise to that is through reflection, which sucks.
   */
  EntityMapper(this.collectionName, this.db, {this.builder, this.idField: '_id'});

  /**
   * Returns Future<[T]> if not in cache, otherwise [T].
   * Usable for asyncMap, since that prevents pausing
   * the stream if entities are cached.
   */
  _createEntityInstance(dynamic id) {
    if (!cache.containsKey(id)) {
      T entity = cache[id] = (builder == null) ? new Entity() : builder()
        ..mapper = this
        ..id = id;
      return entity.start();
    }
    return cache[id];
  }

  /**
   * Queries the database. Returns a stream of unique, self-updating entities.
   */
  Stream<T> find({Map query, bool live: false}) =>
    db.find(collectionName, query: query, projection: [idField], live: live)
      .map((result) => result[idField])
      .transform(unique())
      .asyncMap(_createEntityInstance);

  /**
   * Queries the associated database for raw result maps.
   */
  Stream<Map> rawFind({Map query, List<String> projection, bool live}) =>
    db.find(collectionName, query: query, projection: projection, live: live);

  /**
   * Get a [T] instance with the specific ID if it exists.
   */
  Future<T> get(dynamic id) => find(query: { idField: id }).first;

  /**
   * Creates a new [T] and saves it.
   * If successful, the model gets an id. Otherwise, it throws.
   */
  Future<T> create([Map model = const {}]) =>
    db.insert(collectionName, model)
      .then((Map response) => response[idField])
      .then(_createEntityInstance);
}
