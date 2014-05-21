part of bullet.client.models;

class Ad extends Entity {
  String get title => value['title'];
  num get price => value['price'];
}

@Injectable()
class AdMapper extends EntityMapper<Ad> {
  AdMapper(Database db) : super('ads', db, builder: () => new Ad());
}