part of bullet.client.components;

@Component(
  selector: 'ad',
  publishAs: 'ctrl',
  templateUrl: '/packages/bullet/client/components/ad/ad.html',
  cssUrl: '/packages/bullet/client/components/ad/ad.css',
  map: const { 'model': '=>!model' })
class AdComponent implements AttachAware, DetachAware {
  Ad model;

  bool get isLive => !model.isPaused;

  toggle() => model.isPaused ? attach() : detach();

  attach() {
    if (model != null && model.isPaused) {
      new Future(model.resume)
        .then((_) => print('Resumed ${model.id}'));
    }
  }

  detach() {
    if (model != null && !model.isPaused) {
      new Future(model.pause)
        .then((_) => print('Paused ${model.id}'));
    }
  }}
