part of bullet.common.database;

class MongoDbDatabaseService implements DatabaseService {

  Db mongodb;
  AuthenticationService authentication;

  MongoDbDatabaseService(this.mongodb, this.authentication);

  Stream<Map> find(String collection, {Map criteria, bool live: false, metaData}) {
    cancel() {}
    final controller = new StreamController<Map>(onCancel: cancel);
    mongodb
      .open()
      .then((_) {
        var query = mongodb.collection(collection).find(criteria);
        cancel = query.close;
        query.stream.pipe(controller);
      })
      .catchError(controller.addError);
    return controller.stream;
  }

  Future<Map> insert(String collection, Map object, {metaData}) {
    mongodb
      .open()
      .then((_) => mongodb.collection(collection).insert(object));
      // TODO
  }

  Future update(String collection, Map object, {metaData}) {
    // TODO
  }

  Future<bool> delete(String collection, Map object, {metaData}) {
    // TODO
  }

}
