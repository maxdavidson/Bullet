Bullet
======

Screencast: [Youtube](http://youtu.be/Jsxq1QZ9TTM)

### HOWTO

First, install the Dart virtual machine from [dartlang.org](http://dartlang.org/ "Dart"). Then, run `pub get` while inside root Bullet directory

#### Using Dartium:
* To start to server, run `dart bin/server.dart` in a terminal
* Then, open `localhost:8888` in Dartium

#### Using any browser:
* Run `pub build` in a terminal
* Edit bin/server.dart and change the constant HOME to '../build/web'
* To start to server, run `dart bin/server.dart` in a terminal
* Then, open `localhost:8888` in your browser.