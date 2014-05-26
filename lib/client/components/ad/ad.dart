part of bullet.client.components;

@Component(
  selector: 'ad',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/ad/ad.html',
  cssUrl: '/packages/bullet/client/components/ad/ad.css',
  map: const { 'model': '=>!model' })
class AdComponent implements AttachAware, DetachAware {
  Ad model;
  Router router;

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
