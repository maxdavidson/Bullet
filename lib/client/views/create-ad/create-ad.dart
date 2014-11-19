library bullet.client.views.create_ad;

import 'package:angular/angular.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/client/services/database/entities.dart';


@Component(
  selector: 'create-ad-view',
  templateUrl: 'create-ad.html',
  cssUrl: const ['create-ad.css', '../views.css'])
class CreateAdView {

  final Router router;

  Ad ad;
  User user;

  bool _isLoading = false;
  bool get isLoading => _isLoading && user == null;

  CreateAdView(EntityMapper<Ad> ads, EntityMapper<User> users, this.router) {
    ad = ads.create();
    users.get('me').then((me) => user = me);
  }

  // TODO: validate state before saving
  saveAd() {
    _isLoading = true;
    return ad.save()
      .then((_) {
        if (!user.ads.contains(ad.id)) {
          user.ads.add(ad.id);
          return user.save();
        }
      })
      .then(sideEffect((_) => _isLoading = false))
      .then((_) => router.go('ad', { 'adId': ad.id }) );
  }

}
