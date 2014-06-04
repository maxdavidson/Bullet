library bullet.client.views;

import 'dart:async';
import 'dart:html' as DOM;
import 'dart:math' as Math;

import 'package:angular/angular.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/client/services/authenticator/client.dart';
import 'package:bullet/client/services/authenticator/impl/google.dart';
import 'package:bullet/client/services/authenticator/impl/facebook.dart';

part 'search/search.dart';
part 'login/login.dart';
part 'ad/ad.dart';
part 'profile/profile.dart';
part 'create-ad/create-ad.dart';

class ViewModule extends Module {
  ViewModule() {
    bind(SearchView);
    bind(LoginView);
    bind(AdView);
    bind(ProfileView);
    bind(CreateAdView);
  }
}
