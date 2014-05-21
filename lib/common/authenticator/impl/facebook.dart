library bullet.authenticator.facebook;

import '../client.dart';
export '../client.dart';

import 'js_sdk.dart';
import 'dart:async';
import 'dart:js';

/**
 * A proxy for communicating with the official Facebook JavaScript SDK
 */
class FacebookSDK extends JavaScriptSDK {

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
  Future<Map> _call(String methodName, {Iterable args: const [], bool callbackFirst: false}) {
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

  Future<Map> login({Iterable<String> scope: const []}) =>
    _call('login', args: [{ 'scope': scope.join(',') }], callbackFirst: true)
      .then((response) {
        if (response != null && response['status'] == null)
          throw 'Login failed';
        print('Login successful');
        return response;
      });

  Future<Map> logout() => _call('logout');
  Future<Map> api(String path, {String method: 'get', Map params}) => _call('api', args: [path, method, params]);
  Future<Map> getLoginStatus() => _call('getLoginStatus');

}

class FacebookAuthenticatorClient extends AuthenticatorClient {

  static final String clientId = '1380991668856257';
  final FacebookSDK FB = new FacebookSDK(appId: clientId);

  String _token;

  @override
  String get token => _token;

  @override
  bool get isInitialized => FB.isInitialized;

  @override
  Future init() => FB.init();

  @override
  Future login() => FB.login(scope: ['email'])
/*    FB.getLoginStatus()
      .catchError((_) => FB.login(scope: ['email']))*/
      .then((response) { _token = response['authResponse']['accessToken']; return response['authResponse']; });
}
