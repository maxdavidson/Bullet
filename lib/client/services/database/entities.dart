library bullet.client.entities;

import 'dart:async';

import 'package:angular/angular.dart';

import 'package:bullet/shared/database/mapper.dart';
export 'package:bullet/shared/database/mapper.dart';

import 'package:bullet/client/services/authenticator/client.dart';


class Ad extends Entity {
  String get title => value['title'];
  String get description => value['description'];
  num get price => value['price'];

  set title(val) => value['title'] = val;
  set description(val) => value['description'] = val;
  set price(val) => value['price'] = val;
}

class User extends Entity {
  String get name => value['name'];
  String get phone => value['phone'];
  String get email => value['email'];
  String get color => value['color'];

  set name(val) => value['name'] = val;
  set phone(val) => value['phone'] = val;
  set email(val) => value['email'] = val;
  set color(val) => value['color'] = val;

  List get ads => getField('ads', create: () => []);
  List<Map> get accounts => getField('accounts', create: () => []);
  List<Map> get queries => getField('queries', create: () => []);
}

@Injectable()
class AdMapper extends EntityMapper<Ad> {
  AdMapper(Database db) : super('ads', db, builder: () => new Ad());
}

@Injectable()
class UserMapper extends EntityMapper<User> {

  final ClientAuthenticatorProvider provider;
  final RootScope rootScope;
  Future<User> _me;

  UserMapper(Database db, this.provider, this.rootScope) : super('users', db, builder: () => new User());

  @override
  Future<User> get(dynamic id) {
    if (id == 'me') {
      if (provider.isLoggedIn) {
        if (_me == null) {
            _me = find(query: { 'accounts': { r'$elemMatch': { 'type': provider.auth.type, 'id': provider.auth.userId } } }).first;
            _me.then((User profile) => rootScope.context['user'] = profile);
        }
        return _me;
      }
      throw 'Not logged in';
    }
    return super.get(id);
  }
}

class EntityModule extends Module {
  EntityModule() {
    bind(AdMapper);
    bind(UserMapper);
  }
}