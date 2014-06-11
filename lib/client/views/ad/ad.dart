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

  get isLoading => ad == null;

  AdView(EntityMapper<Ad> ads, RouteProvider rp, Router router) {
    ads.get(rp.parameters['adId'])
      .then((Ad result) => ad = result)
      .catchError((e) => router.go('default', {}));
  }
}
