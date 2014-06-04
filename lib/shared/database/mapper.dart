library bullet.database.mapper;

import 'dart:async';

import 'package:bullet/shared/helpers.dart';
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

  DateTime _created, _updated;

  DateTime _tryParse(String date) => (date == null) ? null : DateTime.parse(date);

  // Need to return the same DateTime instance, without changing the internal state
  DateTime get created {
    var parsed = _tryParse(value['created']);
    if (_created == null || _created.compareTo(parsed) != 0)
      _created = parsed;
    return _created;
  }

  DateTime get updated {
    var parsed = _tryParse(value['updated']);
    if (_updated == null || _updated.compareTo(parsed) != 0)
      _updated = parsed;
    return _updated;
  }

  Entity() : super({}) {
    this.map((update) => 'Update: ${update}').forEach(print);
  }

  getField(String field, {create()}) =>
    value.containsKey(field)
      ? value[field]
      : (create != null)
        ? value[field] = create()
        : null;

  /**
   * Starts subscription to update stream.
   * Returns with self on first update
   */
  Future<Entity> start() {
    if (id == null) return new Future.value(this);
    // Listen for updates
    mapper.rawFind(query: { idField: id }, live: true).pipe(this);
    return this.first.then((_) => this);
  }

  /**
   * Transform the input stream to scan and merge the update
   */
  @override
  Future addStream(Stream<Map> stream) =>
    super.addStream(stream.transform(scan(value, (Map state, Map update) => state..addAll(update))));

  Future<Entity> save() {
    var now = new DateTime.now().toIso8601String();
    value['updated'] = now;
    if (id == null) {
      value['created'] = now;
      return mapper.rawInsert(value)
        .then((Map unique) => id = unique[idField])
        .then((_) => start());
    } else {
      return mapper.rawUpdate(value)
        .then((_) => this);
    }
  }

  Future destroy() {
    // TODO
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
      T entity = cache[id] = create()..id = id;
      return entity.start();
    }
    return cache[id];
  }

  /**
   * Queries the database. Returns a stream of unique, self-updating entities.
   */
  Stream<T> find({Map query, int limit, int skip, Map orderBy, bool live: false}) =>
    db.find(collectionName, query: query, fields: [idField], orderBy: orderBy, limit: limit, skip: skip, live: live)
      .map((result) => result[idField])
      .transform(unique())
      .asyncMap(_createEntityInstance);

  /**
   * Queries the associated database for raw result maps.
   */
  Stream<Map> rawFind({Map query, List<String> fields, bool live}) =>
    db.find(collectionName, query: query, fields: fields, live: live);

  /**
   * Update a raw map
   */
  Future<Map> rawUpdate(Map document) => db.update(collectionName, document);

  /**
   * Insert map into database
   */
  Future rawInsert(Map document) => db.insert(collectionName, document);

  /**
   * Get a [T] instance with the specific ID if it exists.
   */
  Future<T> get(dynamic id) => find(query: { idField: id }).first;

  /**
   * Creates a new [T] connected to this [EntityMapper].
   */
  T create() => ((builder == null) ? new Entity() : builder())..mapper = this;
}
