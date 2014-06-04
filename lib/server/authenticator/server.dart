library bullet.authenticator.server;

import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:oauth2/oauth2.dart' as OAuth2;
import 'package:bullet/shared/authenticator/authenticator.dart';


typedef ServerAuthenticator AuthFactoryFn(Map config);

/**
 * Factory functions for specific keys. Not pretty...
 */
final _factories = <String, AuthFactoryFn> {
  'FB': (Map config) => new FacebookServerAuthenticator.fromConfig(config),
  'GO': (Map config) => new GoogleServerAuthenticator.fromConfig(config)
};

/**
 * User this as a factory for serialized configs.
 */
abstract class ServerAuthenticator extends Authenticator {

  static final _instances = new Map<String, ServerAuthenticator>();

  const ServerAuthenticator();
  const ServerAuthenticator.fromConfig(Map config);

  factory ServerAuthenticator.fromJson(Map json) {
    String type = json['type'];

    if (json == null)
      throw 'Must supply config map';
    if (!json.containsKey('type'))
      throw 'Config map does not define type';
    if (!_factories.containsKey(type))
      throw 'No authenticator defined for type';

    if (!_instances.containsKey(type) || _instances[type] == null || _instances[type].hasExpired)
      _instances[type] = _factories[type](json['config']);

    return _instances[type];
  }

}

abstract class OAuth2Authenticator extends ServerAuthenticator {
  final String appId;
  final String appSecret;

  OAuth2.Client client;
  String get accessToken => client.credentials.accessToken;

  OAuth2Authenticator(this.appId, this.appSecret);

  OAuth2.Client createClient(String token) {
    if (client == null || client.credentials.accessToken != token)
      client = new OAuth2.Client(appId, appSecret, new OAuth2.Credentials(token));
    return client;
  }
}

class FacebookServerAuthenticator extends OAuth2Authenticator {

  static final String host = 'https://graph.facebook.com';
  static final String _appId = '1380991668856257';
  static final String _appSecret = '80706b6165b485ac013ca4a58f141445';

  final String _userId;
  final String _accessToken;
  final DateTime _expiresAt;
  final Map _config;
  Map _cachedResponse;

  @override
  String get userId => _userId;

  @override
  String get type => 'FB';

  @override
  bool get hasExpired => _expiresAt.compareTo(new DateTime.now()) < 0;

  Map get config => _config;

  @override
  String get userName => _cachedResponse == null ? null : _cachedResponse['name'];

  @override
  String get email => _cachedResponse == null ? null : _cachedResponse['email'];

  FacebookServerAuthenticator.fromConfig(Map config) : super(_appId, _appSecret),
    _config = config,
    _userId = config['userID'],
    _accessToken = config['accessToken'],
    _expiresAt = new DateTime.now().add(new Duration(seconds: config['expiresIn']));

  @override
  Future<Map> authenticate() => _cachedResponse != null && !hasExpired
    ? new Future.value(_cachedResponse)
    : createClient(_accessToken)
        .get('$host/me')
        .then((response) {
          if (response.statusCode != 200) throw 'Failed';
          if (hasExpired) throw 'Authenticator has expired';
          return _cachedResponse = JSON.decode(response.body);
        });
}

class GoogleServerAuthenticator extends OAuth2Authenticator {

  static final String host = 'https://www.googleapis.com';
  static final String _appId = '947918727839-1rcsr441fvgm19vl5u8cudvciuvck2mk.apps.googleusercontent.com';
  static final String _appSecret = 'yFozGbXu-ebvz9ifOQsPHoag';

  final String _accessToken;
  final DateTime _expiresAt;
  String _userId;
  Map _config;
  Map _cachedResponse;

  @override
  String get userName => _cachedResponse == null ? null : _cachedResponse['displayName'];

  @override
  String get email => _cachedResponse == null || !_cachedResponse.containsKey('emails')
    ? null
    : _cachedResponse['emails'].firstWhere((Map email) => email['type'] == 'account')['value'];

  @override
  String get userId => _userId;

  @override
  String get type => 'GO';

  @override
  bool get hasExpired => _expiresAt.compareTo(new DateTime.now()) < 0;

  @override
  Map get config => _config;
  
  GoogleServerAuthenticator.fromConfig(Map config) : super(_appId, _appSecret),
    _config = config,
    _accessToken = config['access_token'],
    _expiresAt = new DateTime.now().add(new Duration(seconds: int.parse(config['expires_at'])));
  
  @override
  Future<Map> authenticate() => _cachedResponse != null && !hasExpired
    ? new Future.value(_cachedResponse)
    : createClient(_accessToken)
        .get('$host/plus/v1/people/me')
        .then((httpResponse) {
          var response = JSON.decode(httpResponse.body);
          //print('Google auth response: $response');
          if (httpResponse.statusCode != 200) throw 'Failed';
          if (hasExpired) throw 'Authenticator has expired';
          //print(response);
          _cachedResponse = response;
          _userId = response['id'];
          return response;
        });
}