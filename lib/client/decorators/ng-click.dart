part of bullet.client.decorators;

/**
 * Port of ngTouch's version of ngClick to trigger click events using touch events,
 * thereby preventing the 300ms delay.
 *
 * Not working yet...
 */
@Decorator(
    selector: '[ng-click]',
    map: const { 'ng-click': '&onClick'})
class NgClick {

  static const Duration TAP_DURATION = const Duration(milliseconds: 750); // Shorter than 750ms is a tap, longer is a taphold or drag.
  static const Duration PREVENT_DURATION = const Duration(milliseconds: 2500); // 2.5 seconds maximum from preventGhostClick call to click
  static const int MOVE_TOLERANCE = 12; // 12px seems to work in most mobile browsers.
  static const int CLICKBUSTER_THRESHOLD = 25; // 25 pixels in any dimension is the limit for busting clicks.
  static const String ACTIVE_CLASS_NAME = 'ng-click-active';

  DateTime lastPreventedTime;
  List<DOM.Point> touchCoordinates;
  DOM.Point lastLabelClick;

  Function clickHandler;

  set onClick(Function fn) => clickHandler = fn;

  NgClick(DOM.Element element) {
    bool tapping = false;

    DOM.Element tapElement; // Used to blur the element after a tap.
    DateTime startTime; // Used to check if the tap was held too long.

    DOM.Point touchStart;

    void resetState() {
      tapping = false;
      element.classes.remove(ACTIVE_CLASS_NAME);
    }

    element
      ..onTouchStart.listen((DOM.TouchEvent event) {
      tapping = true;
      tapElement = event.target;

      // Hack for Safari, which can target text nodes instead of containers.
      if (tapElement.nodeType == 3)
        tapElement = tapElement.parentNode;

      startTime = new DateTime.now();
      touchStart = event.touches.first;

      element
        ..classes.add(ACTIVE_CLASS_NAME)
        ..onTouchMove.listen((_) => resetState())
        ..onTouchCancel.listen((_) => resetState())
        ..onTouchEnd.listen((event) {
        Duration diff = new DateTime.now().difference(startTime);

        List<DOM.Touch> touches = (event.changedTouches != null && event.changedTouches.isNotEmpty ) ? event.changedTouches : event.touches;

        DOM.Point point = touches.first.client;
        num dist = point.distanceTo(touchStart);

        if (tapping && diff < TAP_DURATION && dist < MOVE_TOLERANCE) {
          // Call preventGhostClick so the clickbuster will catch the corresponding click.
          preventGhostClick(point);

          // Blur the focused element (the button, probably) before firing the callback.
          // This doesn't work perfectly on Android Chrome, but seems to work elsewhere.
          // I couldn't get anything to work reliably on Android Chrome.
          if (tapElement != null) tapElement.blur();

          element.dispatchEvent(new DOM.MouseEvent('click', clientX: point.x, clientY: point.y));
        }

        resetState();
      });
    })

    // Actual click handler.
    // There are three different kinds of clicks, only two of which reach this point.
    // - On desktop browsers without touch events, their clicks will always come here.
    // - On mobile browsers, the simulated "fast" click will call this.
    // - But the browser's follow-up slow click will be "busted" before it reaches this handler.
    // Therefore it's safe to use this directive on both mobile and desktop.
      ..onClick.listen((_) => clickHandler())
      ..onMouseDown.listen((_) => element.classes.add(ACTIVE_CLASS_NAME))
      ..onMouseMove.listen((_) => element.classes.remove(ACTIVE_CLASS_NAME))
      ..onMouseUp.listen((_) => element.classes.remove(ACTIVE_CLASS_NAME));
  }

  /**
   * Checks if the coordinates are close enough to be within the region.
   */
  bool hit(DOM.Point a, DOM.Point b) =>
    Math.min(((a.x - b.x) as num).abs(), ((a.y - b.y) as num).abs()) < CLICKBUSTER_THRESHOLD;

  /**
   * Checks a list of allowable regions [touchCoordinates] against a click location [click].
   * Returns true if the click should be allowed.
   * Splices out the allowable region from the list after it has been used.
   */
  bool checkAllowableRegions(List<DOM.Point> points, DOM.Point click) {
    check(point) => hit(point, click);
    if (points.any(check)) {
      points.removeWhere(check);
      return true;
    }
    else
     return false;
  }

  /**
   * Global click handler that prevents the click if it's in a bustable zone and preventGhostClick was called recently.
   */
  void handleClick(DOM.MouseEvent event) {
    if (new DateTime.now().compareTo(lastPreventedTime.subtract(PREVENT_DURATION)) > 0)
      return; // Too old.

    DOM.Point click = event.client;

    // Work around desktop Webkit quirk where clicking a label will fire two clicks (on the label
    // and on the input element). Depending on the exact browser, this second click we don't want
    // to bust has either (0,0), negative coordinates, or coordinates equal to triggering label
    // click event
    if (click.x < 1 && click.y < 1)
      return; // offscreen

    if (lastLabelClick != null &&
        lastLabelClick.x == click.x && lastLabelClick.y == click.y)
      return; // input click triggered by label click

    // reset label click coordinates on first subsequent click
    if (lastLabelClick != null)
      lastLabelClick = null;

    // remember label click coordinates to prevent click busting of trigger click event on input
    if ((event.target as DOM.Element).tagName.toLowerCase() == 'label')
      lastLabelClick = click;

    // Look for an allowable region containing this click.
    // If we find one, that means it was created by touchstart and not removed by
    // preventGhostClick, so we don't bust it.
    if (checkAllowableRegions(touchCoordinates, click))
      return;

    // If we didn't find an allowable region, bust the click.
    event.stopPropagation();
    event.preventDefault();

    // Blur focused form elements
    if (event.target != null)
      (event.target as DOM.Element).blur();

  }

  /**
   * Global touchstart handler that creates an allowable region for a click event.
   * This allowable region can be removed by preventGhostClick if we want to bust it.
   */
  void handleTouchStart(DOM.TouchEvent event) {
    DOM.Point touchPoint = event.touches.first.client;
    touchCoordinates.add(touchPoint);
    new Future.delayed(PREVENT_DURATION, () => touchCoordinates.remove(touchPoint));
  }

  /**
   * On the first call, attaches some event handlers. Then whenever it gets called, it creates a
   * zone around the touchstart where clicks will get busted.
   */
  void preventGhostClick(DOM.Point click) {
    if (touchCoordinates != null) {
      DOM.querySelector('html')
        ..onClick.listen(handleClick)
        ..onTouchStart.listen(handleTouchStart);
      touchCoordinates = [];
    }
    lastPreventedTime = new DateTime.now();
    checkAllowableRegions(touchCoordinates, click);
  }

}
