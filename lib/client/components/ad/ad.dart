library bullet.client.components.ad;

import 'package:angular/angular.dart';

import 'package:bullet/client/services/database/entities.dart';


@Component(
  selector: 'ad',
  templateUrl: 'ad.html',
  cssUrl: 'ad.css')
class AdComponent implements AttachAware, DetachAware {

  final Router router;

  @NgOneWayOneTime('model')
  Ad model;

  AdComponent(this.router);

  bool get isLive => !model.isPaused;

  toggle() => model.isPaused ? attach() : detach();

  @override
  attach() {
    if (model != null && model.isPaused)
      model.resume();
  }

  @override
  detach() {
    if (model != null && !model.isPaused)
      model.pause();
  }

}
