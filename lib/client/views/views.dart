library bullet.client.views;

import 'package:angular/angular.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/client/services/authenticator/client.dart';
import 'package:bullet/client/services/authenticator/impl/google.dart';
import 'package:bullet/client/services/authenticator/impl/facebook.dart';

part 'home/home.dart';
part 'login/login.dart';
part 'ad/ad.dart';

class ViewModule extends Module {
  ViewModule() {
    bind(HomeView);
    bind(LoginView);
    bind(AdView);
  }
}
