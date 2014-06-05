import 'dart:async';
import 'package:mongo_dart_query/mongo_dart_query.dart';

/*
typedef S Lambda<T, S>(T);
typedef bool Predicate<T>(T);

Predicate<Iterable<dynamic>>
and(fns) => (x) => fns.every((fn) => fn(x));

Lambda<Iterable<dynamic>, Lambda<dynamic, Predicate<Iterable<dynamic>>>>
or = (fns) => (x) => fns.any((fn) => fn(x));

Lambda<Iterable<dynamic>, Lambda<Lambda<dynamic, dynamic>, Iterable<dynamic>>>
map = (iterable) => (fn) => iterable.map(fn);

Lambda<Iterable<dynamic>, Lambda<Predicate<dynamic>, Iterable<dynamic>>>
filter = (iterable) => (fn) => iterable.where(fn);

Lambda<dynamic, Lambda<Iterable<dynamic>, dynamic>>
fold = (x) => (list) => (fn) => list.fold(x, (c, v) => fn(c)(v));

Lambda<Iterable<Lambda<dynamic, dynamic>>, Lambda<dynamic, dynamic>>
compose = (fns) => (x) => fns.fold(x, (y, fn) => fn(y));

Lambda<num, num> add(a) => (b) => a + b;
Lambda<num, num> subtract(a) => (b) => a - b;
Lambda<num, num> multiply(a) => (b) => a * b;
Lambda<num, num> divide(a) => (b) => a / b;
*/

void main() {
/*
  Lambda<num, String> build = compose([
      add(1),
      multiply(2),
      (num n) => 'Number: $n'
  ]);
*/

  String apa;

  print(apa is String);
  print(apa == null);

}