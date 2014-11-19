library bullet.client.views.search;

import 'dart:async';
import 'dart:html' as DOM;

import 'package:angular/angular.dart';

import 'package:bullet/shared/helpers.dart';
import 'package:bullet/client/services/database/entities.dart';
import 'package:bullet/client/services/authenticator/client.dart';


@Component(
  selector: 'search-view',
  templateUrl: 'search.html',
  cssUrl: const ['search.css','../views.css'])
class SearchView implements AttachAware, DetachAware {

  final EntityMapper<Ad> adMapper;
  final EntityMapper<User> users;

  final ClientAuthenticatorProvider provider;

  final ads = new List<Ad>();

  ClientAuthenticator get auth => provider.auth;
  Iterable<Ad> get active_ads => ads.where((ad) => !ad.isPaused);

  bool queryIsSaved = false;
  int limit = 8;
  bool isLoading = false;
  get isLoggedIn => provider.isLoggedIn;

  final _query = new Query();

  final queries = new StreamController();
  String get query => _query.query;
  String get sortField => _query.sortField;
  bool get ascending => _query.ascending;

  set query(String value) { queries.add(false); _query.query = value; }
  set sortField(String value) { queries.add(false); _query.sortField = value; }
  set ascending(bool value) { queries.add(false); _query.ascending = value; }

  SearchView(this.adMapper, this.users, this.provider, RouteProvider route, Router router, DOM.Window window, NgRoutingUsePushState routing) {

    // if (route.parameters.containsKey('query'))
    //  _query = new Query.fromQueryString(route.parameters['query']);

    queries.stream
      .transform(debounce(const Duration(milliseconds: 500)))
      .forEach((findMore) {
        if (!findMore) resetLimit();

        // Ugly, but need to update url without reloading view, can't do it in router
        if (routing.usePushState)
          window.history.replaceState(null, window.document.title, '/search/${_query.toUri()}');

        runQuery(findMore: findMore);
      });
  }

  get paused => subscription.isPaused;

  increaseLimit() { limit++; queries.add(true); }
  resetLimit() { limit = 8; }

  StreamSubscription<Ad> subscription;

  runQuery({ bool findMore: false}) {
    if (subscription != null) subscription.cancel();
    bool queryIsSaved = false;

    subscription = adMapper.find(
        query: { 'title': { r'$regex': query, r'$options': 'i' } },
        orderBy: { sortField: ascending ? 1 : -1, 'id': ascending ? 1 : -1 },
        skip: findMore ? active_ads.length : null,
        limit: findMore ? 10 : limit,
        live: true)
      .where((ad) => !ads.contains(ad))
      .listen(ads.add);
  }

  Future saveQuery() {
    if (provider.isLoggedIn)
      return users.get('me').then((User me) {
        me.queries.add(_query.toJson());
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
