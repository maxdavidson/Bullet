library bullet.client.views;

import 'package:angular/angular.dart';

part 'home/home.dart';

class ViewModule extends Module {
  ViewModule() {
    bind(HomeView);
  }
}
