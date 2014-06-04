part of bullet.client.decorators;

@Decorator(
    selector: '[bullet-click]',
    map: const {
        'bullet-click': '@action',
        'bullet-click-hold': '@hold',
        'bullet-click-release' : '@release'})
class BulletClick {

  final NgElement element;

  Function action, hold, release;

  BulletClick(this.element, VmTurnZone zone) {
    zone.runOutsideAngular(() {

      if (hold != null) {
        element.node
          ..onTouchStart.listen((event) => hold())
          ..onMouseDown.listen((event) {
            print(event.button);
            hold();
          });
      }

      if (action != null) {
        element.node
          ..onTouchEnd.listen((event) => action())
          ..onClick.listen((event) => action());
      }

      if (release != null) {
        element.node
          ..onTouchEnd.listen((event) => release())
          ..onMouseUp.listen((event) => release());
      }

    });
  }
}