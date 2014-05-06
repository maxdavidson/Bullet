library bullet.client.models;

import 'package:angular/angular.dart';
import 'package:bullet/common/database/database.dart';
export 'package:bullet/common/database/database.dart';

part 'ad.dart';

class ModelModule extends Module {
  ModelModule() {
    bind(AdCollection);
  }
}