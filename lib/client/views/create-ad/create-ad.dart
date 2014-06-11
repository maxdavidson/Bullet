part of bullet.client.views;

@Component(
  selector: 'create-ad-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/create-ad/create-ad.html',
  cssUrl: const [
      '/packages/bullet/client/views/create-ad/create-ad.css',
      '/packages/bullet/client/views/views.css'])
class CreateAdView {

  final Router router;

  Ad ad;
  User user;

  bool _isLoading = false;
  bool get isLoading => _isLoading && user == null;

  CreateAdView(EntityMapper<Ad> ads, EntityMapper<User> users, this.router) {
    ad = ads.create();
    users.get('me').then((User me) => user = me);
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
