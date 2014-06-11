part of bullet.client.views;


@Component(
  selector: 'search-view',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/views/search/search.html',
  cssUrl: const [
      '/packages/bullet/client/views/search/search.css',
      '/packages/bullet/client/views/views.css'])
class SearchView implements AttachAware, DetachAware {

  final Scope scope;
  final EntityMapper<Ad> adMapper;
  final UserMapper users;

  final ClientAuthenticatorProvider provider;

  final queries = new StreamController();
  final ads = new List<Ad>();

  StreamSubscription<Ad> subscription;

  ClientAuthenticator get auth => provider.auth;
  Iterable<Ad> get active_ads => ads.where((ad) => !ad.isPaused);

  bool queryIsSaved = false;
  int limit = 8;

  // For the view fading...
  bool isLoading = false;

  var query = new Query();

  SearchView(this.adMapper, this.users, this.scope, this.provider, RouteProvider route, Router router, DOM.Window window, NgRoutingUsePushState routing) {

    if (route.parameters.containsKey('query'))
      query = new Query.fromQueryString(route.parameters['query']);

    addQuery(a,b) => queries.add(false);
    scope
      ..watch('ctrl.query.query', addQuery, canChangeModel: false)
      ..watch('ctrl.query.sortField', addQuery, canChangeModel: false)
      ..watch('ctrl.query.ascending', addQuery, canChangeModel: false);

    queries.stream
      .transform(debounce(const Duration(milliseconds: 500)))
      .forEach((findMore) {
        if (!findMore) resetLimit();

        // Ugly, but need to update url without reloading view, can't do it in router
        if (routing.usePushState)
          window.history.replaceState(null, window.document.title, '/search/${query.toUri()}');

        runQuery(findMore: findMore);
      });
  }

  get paused => subscription.isPaused;

  void increaseLimit() { limit++; queries.add(true); }
  void resetLimit() { limit = 8; }

  void runQuery({ bool findMore: false}) {
    if (subscription != null) subscription.cancel();
    bool queryIsSaved = false;

    not(bool f(x)) => (x) => !f(x);
    later(ms) => (x) => new Future.delayed(new Duration(milliseconds: ms), () => x);
    apply(f(x)) => (x) => scope.apply(() => f(x));

    subscription = adMapper.find(
        query: { 'title': { r'$regex': query.query, r'$options': 'i' } },
        orderBy: { query.sortField: query.ascending ? 1 : -1, 'id': query.ascending ? 1 : -1 },
        skip: findMore ? active_ads.length : null,
        limit: findMore ? 10 : limit,
        live: true)
      .where(not(ads.contains))
      .listen((ad) => later(50)(ad).then(apply(ads.add)));
  }

  Future saveQuery() {
    if (provider.isLoggedIn)
      return users.get('me').then((User me) {
        me.queries.add(query.toJson());
        isLoading = true;
        return me.save()
          .then(sideEffect((_) => isLoading = false))
          .then(sideEffect((_) => queryIsSaved = true));
      });
    return null;
  }

  @override
  attach() => runQuery();

  @override
  detach() { if (subscription != null) subscription.cancel(); }

}
