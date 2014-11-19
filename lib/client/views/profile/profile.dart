library bullet.client.views.profile;

import 'dart:async';

import 'package:angular/angular.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/client/services/authenticator/client.dart';


@Component(
  selector: 'profile-view',
  templateUrl: 'profile.html',
  cssUrl: const ['profile.css','../views.css'])
class ProfileView {

  static const _colors = const [
    "#86EFCD","#F69D92","#E7ED85","#D2C2F2","#E5E1C1","#DAAA63","#8CC1D1","#F0A7C9",
    "#9EB96F","#EFDEE7","#BFF49E","#C5F3E3","#84C894","#C5AF89","#74C7BC","#E5B5A6",
    "#BBBCB2","#D5F6B9","#D0C56C","#B1BDDB","#AABF9F","#8FE4EF","#98EEB3","#B7CF95",
    "#D7B8BC","#EEA470","#DFC88C","#C5E8C4","#E7B68C","#BDD3D1","#99DCB9","#EBC165",
    "#EAAFBD","#87EDDF","#EFE3AC","#EDE0D5","#A6D388","#6ED2AC","#F5AF95","#BBE181",
    "#C0CE76","#D4B6D8","#D8EAA0","#9CCDC3","#AEE2A5","#E0F0E3","#E3C378","#A8CDF1",
    "#C0BE86","#DFD8F1","#B6F6CD","#D2BFA2","#C4D0DB","#F4BC78"
  ];

  final ClientAuthenticatorProvider provider;

  User user;

  bool _isLoading = false;

  get isLoading => _isLoading || user == null;
  get colors => _colors;

  ProfileView(EntityMapper<User> users, RouteProvider rp, Router router, this.provider) {
    new Future(() => users.get(rp.parameters['userId']))
      .then((User profile) => user = profile)
      .catchError((_) => router.go('login', {}));
  }

  String getUri(Map query) => new Query.fromJson(query).toUri();

  void setColor(String color) {
    _isLoading = true;
    user.color = color;
    user.save().whenComplete(() => _isLoading = false);
  }

}
