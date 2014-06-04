library bullet.client.decorators;

import 'dart:html' as DOM;
import 'dart:math' as Math;
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:bullet/client/services/database/entities.dart';

part 'push-href.dart';
part 'bullet-click.dart';
part 'ng-click.dart';

class DecoratorModule extends Module {
  DecoratorModule() {
    bind(BulletClick);
    bind(PushHref);
    //bind(NgClick);
  }
}