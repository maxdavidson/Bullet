library bullet.helpers;

import 'dart:async';


class Query {
  String query = '';
  String sortField = 'updated';
  bool ascending = false;

  Query();

  Query.fromJson(Map json) {
    if (json.containsKey('query'))
      query = json['query'];
    if (json.containsKey('sort') && ['updated', 'price'].contains(json['sort']))
      sortField = json['sort'];
    if (json.containsKey('order'))
      ascending = json['order'] == 'asc';
  }

  factory Query.fromQueryString(String query) => new Query.fromJson(Uri.splitQueryString(query));

  Map toJson() => { 'query': query, 'sort': sortField, 'order': ascending ? 'asc' : 'desc' };

  String toUri() => new Uri(queryParameters: toJson()).toString().substring(1);
}

/**
 * Perform a side effect in a stream if it is listened to.
 ** stream.map(sideEffect((value) => doSomething(value)));
 */
sideEffect(fn(value)) => (value) { fn(value); return value; };


/**
 * A reactive property that keeps track of the latest received event from the stream.
 * Also acts as a stream itself, broadcasting distinct update events.
 */
class ReactiveProperty<T> extends Stream<T> implements StreamConsumer<T> {
  T _value;
  T get value => _value;
  void set value(T newValue) => controller.add(_value = newValue);

  StreamSubscription<T> _subscription;
  final controller = new StreamController<T>.broadcast(sync: true);


  ReactiveProperty([T defaultValue = null]) : _value = defaultValue {
    if (defaultValue != null) controller.add(defaultValue);
    controller.stream.forEach((val) => _value = val);
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
      .then((_) => _subscription = stream.listen(controller.add, onError: controller.addError))
      .then((_) => _subscription.asFuture());
  }

  Future close() => controller.close();

  StreamSubscription<T> listen(void onData(T data), {Function onError, void onDone(), bool cancelOnError}) =>
    controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
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