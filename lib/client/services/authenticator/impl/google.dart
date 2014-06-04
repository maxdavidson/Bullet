library bullet.authenticator.google;

import '../client.dart';
export '../client.dart';

import 'js_sdk.dart';
import 'dart:async';
import 'dart:js';

_callOnce(Function f) {
  bool called = false;
  return (val) {
    if (!called) {
      f(val);
      called = true;
    }
  };
}

/**
 * A proxy for communicating with the Google+ JavaScript SDK
 */
class GoogleSDK extends JavaScriptLibrary {

  final String clientId;

  GoogleSDK(this.clientId) :
    super('gapi',
      scriptUri: 'https://apis.google.com/js/client:plusone.js',
      callbackParam: 'onload');

  Future _loadPlusSDK() {
    var completer = new Completer<Map>();
    SDK['client'].callMethod('load', ['plus', 'v1', completer.complete]);
    return completer.future;
  }
  
  Future<Map> signIn({Iterable<String> scope: const []}) {
    var completer = new Completer<JsObject>();
    // Google SDK calls the callback twice, need to make sure it only works once
    SDK['auth'].callMethod('signIn', [
      new JsObject.jsify({
        'clientid': clientId,
        'cookiepolicy': 'single_host_origin',
        'callback': _callOnce(completer.complete)//'monkeyButt',
      })
    ]);
    return completer.future
      .then((JsObject obj) => _loadPlusSDK().then((_) => obj))
      .then(convertJsObject);
  }

  Future<Map> getUserInfo({userId: 'me'}) {
    var completer = new Completer();
    SDK['client']['plus']['people']
      .callMethod('get', [new JsObject.jsify({ 'userId': userId })])
      .callMethod('execute', [(response, _) => completer.complete(response)]);
    return completer.future.then(convertJsObject);
  }

  void signOut() => SDK['auth'].callMethod('signOut', []);

}

class GoogleClientAuthenticator extends ClientAuthenticator {

  static final String clientId = '947918727839-1rcsr441fvgm19vl5u8cudvciuvck2mk.apps.googleusercontent.com';

  final GoogleSDK GOO = new GoogleSDK(clientId);

  Map _config;
  DateTime _expiresAt;
  Map _info;

  @override
  String get userName => _info == null ? null : _info['displayName'];

  @override
  String get email => _info == null || _info.containsKey('emails') ? null : _info['emails'][0]['value'];

  @override
  String get userId => _info == null ? null : _info['id'];

  @override
  String get type => 'GO';

  @override
  bool get hasExpired => new DateTime.now().compareTo(_expiresAt) >= 0;

  @override
  Map get config => { 'type': type, 'config': _config };

  @override
  Future authenticate() => GOO.getUserInfo().then((Map info) => _info = info);

  @override
  bool get isInitialized => GOO.isInitialized;

  Future _init;

  @override
  Future init() => (_init != null) ? _init : _init = GOO.init();

  @override
  Future login() =>
    GOO.signIn(scope: ['email', 'profile'])
       .then((response) {
         var expiresIn = int.parse(response['expires_in']);
         _expiresAt = new DateTime.now().add(new Duration(seconds: expiresIn));
         _config = response;
         return response;
       })
       .then((_) => authenticate());

  @override
  Future logout() => new Future(GOO.signOut);

}