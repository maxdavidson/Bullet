library bullet.client.views;

import 'package:angular/angular.dart';
import 'package:bullet/common/authenticator/client.dart';
import 'package:bullet/common/authenticator/impl/google.dart';
import 'package:bullet/common/authenticator/impl/facebook.dart';

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
