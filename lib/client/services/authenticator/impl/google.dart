library bullet.authenticator.google;

import '../client.dart';
export '../client.dart';

import 'js_sdk.dart';
import 'dart:async';
import 'dart:js';

import 'package:jwt/base64url.dart';

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

  String _clientId;

  GoogleSDK({String clientId}) : _clientId = clientId,
    super('gapi',
      scriptUri: 'https://apis.google.com/js/client:plusone.js',
      callbackParam: 'onload');

  Future<Map> signIn({Iterable<String> scope: const []}) {
    var completer = new Completer<JsObject>();
    // Google SDK calls the callback twice, need to make sure it only works once
    SDK['auth'].callMethod('signIn', [
      new JsObject.jsify({
        'clientid': _clientId,
        'cookiepolicy': 'single_host_origin',
        'callback': _callOnce(completer.complete)//'monkeyButt',
      })
    ]);
    return completer.future.then(convertJsObject);
  }

  void signOut() => SDK['auth'].callMethod('signOut', []);

}

class GoogleClientAuthenticator extends ClientAuthenticator {

  static final String clientId = '947918727839-1rcsr441fvgm19vl5u8cudvciuvck2mk.apps.googleusercontent.com';

  final GoogleSDK GOO = new GoogleSDK(clientId: clientId);

  Map _config;
  DateTime _expiresAt;

  @override
  String get userId;

  @override
  bool get hasExpired => new DateTime.now().compareTo(_expiresAt) >= 0;

  @override
  Map get config => { 'type': 'GO', 'config': _config };

  @override
  Future authenticate();

  @override
  bool get isInitialized => GOO.isInitialized;

  @override
  Future init() => GOO.init();

  @override
  Future login() =>
    GOO.signIn(scope: ['email', 'profile'])
       .then((response) {
         var expiresIn = int.parse(response['expires_in']);
         _expiresAt = new DateTime.now().add(new Duration(seconds: expiresIn));
         _config = response;
         return response;
       });

  @override
  Future logout() => new Future(GOO.signOut);

}