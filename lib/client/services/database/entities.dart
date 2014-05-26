library bullet.client.entities;

import 'package:angular/angular.dart';

import 'package:bullet/shared/database/mapper.dart';
export 'package:bullet/shared/database/mapper.dart';


class Ad extends Entity {
  String get title => value['title'];
  num get price => value['price'];

  set title(val) => value['title'] = val;
  set price(val) => value['price'] = val;
}

class Person extends Entity {
  String get name => value['name'];
  List<Map> get queries => value['queries'];
}


@Injectable()
class AdMapper extends EntityMapper<Ad> {
  AdMapper(Database db) : super('ads', db, builder: () => new Ad());
}

@Injectable()
class PersonMapper extends EntityMapper<Person> {
  PersonMapper(Database db) : super('people', db, builder: () => new Person());
}


class EntityModule extends Module {
  EntityModule() {
    bind(AdMapper);
    bind(PersonMapper);
  }
}