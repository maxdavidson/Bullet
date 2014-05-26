part of bullet.client.views;

@Component(
  selector: 'ad-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/ad/ad.html',
  cssUrl: '/packages/bullet/client/views/ad/ad.css')
class AdView {
  Ad ad;
  AdView(AdMapper mapper, RouteProvider rp, Router router) {
    mapper.get(rp.parameters['adId'])
      .then((Ad result) {
        ad = result;
      })
      .catchError((e) => router.go('home', {}));
  }
}
