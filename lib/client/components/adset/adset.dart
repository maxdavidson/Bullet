part of bullet.client.components;

@Component(
  selector: 'adset',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/adset/adset.html',
  cssUrl: '/packages/bullet/client/components/adset/adset.css',
  map: const { 'query': '<=>query' })
class AdsetComponent implements DetachAware {

  final AdMapper mapper;
  final queries = new StreamController<String>();
  final set = new ReactiveProperty<Set<Ad>>(new Set<Ad>());

  //Iterable<Ad> get ads => set.value;
  List<Ad> ads = new List<Ad>();
  //Iterable<Ad> get active_ads => ads.where((ad) => !ad.isPaused);

  String query = '';
  int limit = 8;

  AdsetComponent(
      this.mapper,
      Scope scope,
      RouteProvider route,
      Router router,
      dom.Window window,
      NgRoutingUsePushState routing)
  {
    set.listen((vals) => vals.forEach((ad) { if (!ads.contains(ad)) ads.add(ad); }));

    var title = window.document.title;
    scope.watch('ctrl.query', (curr, prev) => queries.add(curr));
    queries.stream
      .transform(debounce(const Duration(milliseconds: 500)))
      .forEach((val) {
        limit = 8;

        // Need to update url without reloading view, can't do it in router
        if (routing.usePushState)
          window.history.replaceState(null, title, '/find/$val');

        runQuery(val);
      });
   // runQuery();
  }

  void increaseLimit() { if (set != null && set.isPaused) set.resume(); }

  void runQuery([String input = '']) {
    mapper.find(query: {
        r'$query': { 'title': { r'$regex': input, r'$options': 'i' } } ,
        'orderby': { '_id' : -1 }
      }, live: true)
      .transform(scan(set.value, (Set<Ad> set, Ad ad) => set..add(ad)))
      .pipe(set);
  }

  @override
  detach() => set.cancel();
}
