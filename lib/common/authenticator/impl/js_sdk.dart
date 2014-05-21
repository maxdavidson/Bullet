import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:convert';
import 'dart:math';
import 'package:jwt/base64url.dart';

class JavaScriptSDK {

  bool _initialized = false;
  String _SDK;
  String scriptUri;
  String _callbackParam;

  bool get isInitialized => _initialized;
  JsObject get SDK => context[_SDK];

  JavaScriptSDK(String SDK, {this.scriptUri, String callbackParam})
    : _SDK = SDK, _callbackParam = callbackParam;

  /**
   * Convert a JsObject into a native Dart Map or List
   */
  convertJsObject(JsObject js) =>
    JSON.decode(context['JSON'].callMethod('stringify', [js]));

  /**
   * Inject a script tag and wait for it to load.
   * If [callbackParam] is given, the script will be given a callback parameter
   * that determines when the future completes. Otherwise, it completes when
   * the script is loaded from the injected script tag.
   */
  Future _injectJsScript(String url, {String callbackParam}) {
    var completer = new Completer();
    var script = document.createElement('script')
      ..setAttribute('async', 'async');

    var randomString = BASE64URL.encode(new Iterable.generate(10, (n) => new Random().nextInt(255)).toList());

    document.querySelector('head').append(script);

    if (callbackParam != null)
      context[randomString] = completer.complete;
    else
      script.onLoad.first.then(completer.complete);

    script.onError.first.then(completer.completeError);
    script.setAttribute('src', (callbackParam == null) ? url : '$url?$callbackParam=$randomString');

    return completer.future
      .then((JsObject obj) { if (callbackParam != null) context.deleteProperty(randomString); return obj; });
  }

  Future init() => scriptUri == null || _initialized
    ? new Future.value(null)
    : _injectJsScript(scriptUri, callbackParam: _callbackParam)
      .then((_) => _initialized = true);

}