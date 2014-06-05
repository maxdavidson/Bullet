library bullet.authenticator.client.facebook;

import '../client.dart';
export '../client.dart';

import 'js_sdk.dart';
import 'dart:async';
import 'dart:js';

/**
 * A proxy for communicating with the official Facebook JavaScript SDK
 */
class FacebookSDK extends JavaScriptLibrary {

  String _appId;
  String _version = 'v2.0';

  FacebookSDK({String appId}) : _appId = appId,
    super('FB', scriptUri: '//connect.facebook.net/en_US/sdk.js');

  @override
  Future init() => isInitialized ? new Future.sync(() => null) :
    super.init().then((_) =>
      SDK.callMethod('init', [new JsObject.jsify({ 'appId': _appId, 'version': _version })]));

  /**
   * Return a future of the result of a call to Facebook's API
   */
  Future<Map> _callAsyncMethod(String methodName, {Iterable args: const [], bool callbackFirst: false}) {
    var completer = new Completer();
    Iterable concat(Iterable a, Iterable b) => [a, b].expand((i) => i);

    args = args.map((obj) => (obj is Map || obj is List) ? new JsObject.jsify(obj) : obj);
    args = callbackFirst
      ? concat([completer.complete], args).toList()
      : concat(args, [completer.complete]).toList();

    SDK.callMethod(methodName, args);
    return completer.future
      .then((JsObject response) {
        if (response != null && response.hasProperty('error'))
          throw response['error'];
        return response;
      })
      .then(convertJsObject);
  }

  Object _callMethod(String methodName, {Iterable args: const []}) {
    args = args.map((obj) => (obj is Map || obj is List) ? new JsObject.jsify(obj) : obj).toList();
    var result = SDK.callMethod(methodName, args);
    return convertJsObject(result);
  }

  Future<Map> login({Iterable<String> scope: const []}) =>
    _callAsyncMethod('login', args: [{ 'scope': scope.join(',') }], callbackFirst: true)
      .then((response) {
        if (response != null && response['status'] == null)
          throw 'Login failed';
        print('Login successful');
        return response;
      });

  Future<Map> logout() => _callAsyncMethod('logout');
  Future<Map> api(String path, {String method: 'get', Map params}) => _callAsyncMethod('api', args: [path, method, params]);
  Future<Map> getLoginStatus() => _callAsyncMethod('getLoginStatus');

  Future<Map> getUserInfo({userId: 'me'}) => api('/$userId');

  String getAccessToken() => _callMethod('getAccessToken');
  String getUserID() => _callMethod('getUserID');
  Map getAuthResponse() => _callMethod('getAuthResponse');

}

class FacebookClientAuthenticator extends ClientAuthenticator {

  static final String clientId = '1380991668856257';

  final FacebookSDK FB = new FacebookSDK(appId: clientId);

  DateTime _expiresAt;
  Map _userInfo;

  @override
  Map get config => isInitialized ? { 'type': type, 'config': FB.getAuthResponse() } : null;

  @override
  String get userId => FB.getUserID();

  String get firstName => _userInfo == null ? null : _userInfo['first_name'];
  String get lastName => _userInfo == null ? null : _userInfo['last_name'];

  @override
  String get userName => '$firstName $lastName';

  @override
  String get email => _userInfo == null ? null : _userInfo['email'];

  @override
  String get type => 'FB';

  @override
  bool get hasExpired => new DateTime.now().compareTo(_expiresAt) >= 0;

  @override
  Future authenticate() => FB.getLoginStatus();

  @override
  bool get isInitialized => FB.isInitialized;

  Future _init;

  @override
  Future init() => (_init != null) ? _init : _init = FB.init();

  @override
  Future login() => authenticate()
    .then((Map response) { if (response['status'] != 'connected') throw 'Not logged in'; return response; })
    .catchError((_) => FB.login(scope: ['email']))
    .then((Map response) {
       var authResponse = response['authResponse'];
      _expiresAt = new DateTime.now().add(new Duration(seconds: authResponse['expiresIn']));
      return FB.getUserInfo()
        .then((Map info) => _userInfo = info)
        .then(print)
        .then((_) => authResponse);
      });

  @override
  Future logout() => FB.logout();

}
