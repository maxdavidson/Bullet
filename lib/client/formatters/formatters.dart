library bullet.client.formatters;

import 'package:intl/intl.dart';
import 'package:angular/angular.dart';

part 'nicedate.dart';

class FormattersModule extends Module {
  FormattersModule() {
    bind(NiceDate);
  }
}
