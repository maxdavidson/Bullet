part of bullet.client.components;

@Component(
  selector: 'adset',
  publishAs: 'ctrl',
  templateUrl: 'packages/bullet/client/components/adset/adset.html',
  cssUrl: 'packages/bullet/client/components/adset/adset.css',
  map: const { 'query': '=>query' })
class AdsetComponent {

  List<Ad> ads;
  String query = '';
  AdCollection collection;

  AdsetComponent(this.collection) {
    reload();
  }

  reload() {
    ads = [];
    collection.find().listen(ads.add);
    /*
    var adsToCome = [
        new Ad()..update({ 'title': 'En gammal byrå', 'price': 50 }),
        new Ad()..update({ 'title': 'Två stora bananer säljes!', 'price': 500 }),
        new Ad()..update({ 'title': 'Pajaskokos!', 'price': 13 }),
        new Ad()..update({ 'title': 'Ät mina kortbyxor!', 'price': 399 }),
        new Ad()..update({ 'title': 'Äppelkaka!!', 'price': 25 }),
    ];
    adsToCome.forEach((ad) => ad.update({ 'date':  new DateTime.now() }));

    new Stream.fromIterable(adsToCome)
      .asyncMap((Ad ad) => new Future.delayed(const Duration(milliseconds: 25), () => ad))
      .listen(ads.add);
  */
  }

}
