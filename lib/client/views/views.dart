library bullet.client.views;

import 'package:angular/angular.dart';

import 'search/search.dart';
import 'login/login.dart';
import 'ad/ad.dart';
import 'profile/profile.dart';
import 'create-ad/create-ad.dart';

class ViewModule extends Module {
  ViewModule() {
    bind(SearchView);
    bind(LoginView);
    bind(AdView);
    bind(ProfileView);
    bind(CreateAdView);
  }
}
