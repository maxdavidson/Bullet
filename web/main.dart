import 'package:angular/application_factory.dart';
import 'package:bullet/client/client.dart';

import 'package:bullet/common/authenticator/impl/facebook.dart';
import 'package:bullet/common/authenticator/impl/google.dart';

import 'package:jwt/json_web_token.dart';

void main() {

  /*
  var google = new GoogleAuthenticatorClient();
  var facebook = new FacebookAuthenticatorClient();

  google.login().then((_) {
    print(google.token);
  })
  .then((_) => facebook.login()).then((_) {
    print(facebook.token);
  });
*/
  applicationFactory()
    ..addModule(new AppModule())
    ..run();
}