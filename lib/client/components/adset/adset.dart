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
  final list = new ReactiveProperty<List<Ad>>(new List<Ad>());

  List<Ad> get ads => list.value;

  String query = '';
  int limit = 5;

  AdsetComponent(this.mapper, Scope scope, RouteProvider route) {
    set.map((Set set) => set.toList()).pipe(list);

    scope.watch("ctrl.query", (curr, prev) => queries.add(curr));

    queries.stream
      .transform(debounce(const Duration(milliseconds: 500)))
      .forEach(runQuery);
  }

  void increaseLimit() { limit++; }

  void runQuery([String input]) {
    limit = 5;
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
