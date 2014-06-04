part of bullet.client.views;

@Component(
  selector: 'ad-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/ad/ad.html',
  cssUrl: const [
    '/packages/bullet/client/views/ad/ad.css',
    '/packages/bullet/client/views/views.css'])
class AdView {
  Ad ad;
  User user;

  get isLoading => ad == null;

  AdView(AdMapper ads, RouteProvider rp, Router router) {
    ads.get(rp.parameters['adId'])
      .then((Ad result) => ad = result)
     // .timeout(const Duration(seconds: 5))
      .catchError((e) => router.go('default', {}));
  }
}
