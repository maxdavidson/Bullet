library bullet.helpers;

import 'dart:async';

/**
 * A reactive property that keeps track of the latest received event from the stream.
 * Also acts as a stream itself, broadcasting distinct update events.
 */
class ReactiveProperty<T> extends Stream<T> implements StreamConsumer<T> {
  T _value;
  T get value => _value;
  void set value(T newValue) => _controller.add(_value = newValue);

  StreamSubscription<T> _subscription;
  final _controller = new StreamController<T>.broadcast(sync: true);

  StreamController<T> get controller => _controller;

  ReactiveProperty([T defaultValue = null]) : _value = defaultValue {
    if (defaultValue != null) _controller.add(defaultValue);
    _controller.stream.forEach((val) => _value = val);
  }

  void pause() => _subscription.pause();
  void resume() => _subscription.resume();

  Future cancel() {
    Future future;
    if (_subscription != null)
      future = _subscription.cancel();
    return future;
  }

  bool get isPaused => _subscription.isPaused;

  void notify() => controller.add(value);

  /**
   * Cancels the old subscription first
   */
  Future addStream(Stream<T> stream) {
    var future = cancel();
    if (future != null) future = future.then(() => null);
    else future = new Future.value();

    return future
      .then((_) => _subscription = stream.listen(_controller.add, onError: _controller.addError))
      .then((_) => _subscription.asFuture());
  }

  Future close() => _controller.close();

  StreamSubscription<T> listen(void onData(T data), {Function onError, void onDone(), bool cancelOnError}) =>
    _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

StreamTransformer debounce(Duration wait, {bool immediate: false}) {
  var timer, lastEvent;
  return new StreamTransformer.fromHandlers(handleData: (event, EventSink sink) {
    lastEvent = event;
    if (timer != null && timer.isActive)timer.cancel(); else if (immediate)sink.add(event);
    timer = new Timer(wait, () {
      if (!immediate && lastEvent != null)sink.add(lastEvent);
    });
  },

  handleDone: (EventSink sink) {
    if (timer != null && timer.isActive) timer.cancel();
    sink.close();
  },

  handleError: (error, StackTrace stackTrace, EventSink sink) {
    if (timer != null && timer.isActive) timer.cancel();
    sink.addError(error);
  });
}

StreamTransformer throttle(Duration interval, {bool immediate: false}) {
  var lastEvent, timer;
  return new StreamTransformer.fromHandlers(
      handleData: (event, EventSink sink) {
        if (timer == null || !timer.isActive) {
          if (immediate) sink.add(event);
          timer = new Timer.periodic(interval, (Timer timer) {
            if (lastEvent != null) {
              if (lastEvent != event)
                sink.add(lastEvent);
              else
                timer.cancel();
            }
            lastEvent = event;
          });
        }
      },
      handleDone: (EventSink sink) {
        if (timer != null) timer.cancel();
        sink.close();
      },
      handleError: (error, StackTrace stackTrace, EventSink sink) {
        if (timer != null) timer.cancel();
        sink.addError(error);
      });
}

StreamTransformer scan(initialValue, combine(previousValue, currentValue)) {
  var accumulator = initialValue;
  return new StreamTransformer.fromHandlers(handleData: (event, EventSink sink) =>
    sink.add(accumulator = combine(accumulator, event)));
}

StreamTransformer merge(Stream otherStream) {
  var subscription;
  return new StreamTransformer.fromHandlers(
    handleData: (event, EventSink sink) {
      sink.add(event);
      if (subscription == null)
          subscription = otherStream.listen(sink.add);
    });
}

StreamTransformer unique([dynamic selector(dynamic)]) {
  var items = new Set();
  return new StreamTransformer.fromHandlers(
    handleData: (event, EventSink sink) {
      var item = selector == null ? event : selector(event);
      if (!items.contains(item)) {
        items.add(item);
        sink.add(event);
      }
    }
  );
}