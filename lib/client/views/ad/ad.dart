library bullet.client.views.ad;

import 'package:angular/angular.dart';

import 'package:bullet/client/services/database/entities.dart';


@Component(
  selector: 'ad-view',
  templateUrl: 'ad.html',
  cssUrl: const ['ad.css', '../views.css'])
class AdView {
  Ad ad;

  get isLoading => ad == null;

  AdView(EntityMapper<Ad> ads, RouteProvider rp, Router router) {
    ads.get(rp.parameters['adId'])
      .then((Ad result) => ad = result)
      .catchError((e) => router.go('default', const {}));
  }
}
