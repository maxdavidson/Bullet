import 'package:angular/application_factory.dart';
import 'package:bullet/client/client.dart';

void main() {
  applicationFactory()
    ..addModule(new AppModule())
    ..run();
}
