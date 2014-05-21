import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:oauth2/oauth2.dart' as OAuth2;

abstract class AuthenticatorServer {
  final String appId;
  final String appSecret;

  OAuth2.Client client;
  String get accessToken => client.credentials.accessToken;

  AuthenticatorServer(this.appId, this.appSecret);

  /*
  /**
   * A service may return a one-time code that needs to be exchange for
   */
  Future<Map> getCredentialsFromCode(String code);
*/

  /**
   * Create a client
   */
  OAuth2.Client createClient(String token) =>
    client = new OAuth2.Client(appId, appSecret, new OAuth2.Credentials(token));

  /**
   * Check if the credentials are authorized.
   * Throws if credentials are not authorized.
   */
  Future authenticate(String token);
}

class FacebookAuthenticatorServer extends AuthenticatorServer {
  final String host = 'https://graph.facebook.com';

  FacebookAuthenticatorServer()
    : super('1380991668856257', '80706b6165b485ac013ca4a58f141445');

  Future<Map> authenticate(String token) =>
    createClient(token)
      .get('$host/me')
      .then((response) {
        if (response.statusCode != 200) throw 'Failed';
        return JSON.decode(response.body);
      });
}

class GoogleAuthenticatorServer extends AuthenticatorServer {
  final String host = 'https://www.googleapis.com';

  GoogleAuthenticatorServer()
    : super('947918727839-1rcsr441fvgm19vl5u8cudvciuvck2mk.apps.googleusercontent.com', 'yFozGbXu-ebvz9ifOQsPHoag');

  Future<Map> authenticate(String token) =>
    createClient(token)
      .get('$host/plus/v1/people/me')
      .then((response) {
        var body = JSON.decode(response.body);
        print(body);
        //if (response.statusCode != 200) throw 'Failed';
        return body;
      });
}
