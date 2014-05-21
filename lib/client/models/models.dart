library bullet.client.models;

import 'package:angular/angular.dart';
import 'package:bullet/common/database/mapper.dart';

part 'ad.dart';

class EntityMapperModule extends Module {
  EntityMapperModule() {
    // bind(Collection<Ad>, toImplementation: AdCollection);
    bind(AdMapper);
  }
}