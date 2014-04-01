Bullet
======

### Functional specification
#### Service:
Bullet is the working name for a web service allowing users to buy and sell things online. It will be similar in functionality to sites like Blocket or Craigslist, but with a focus on quick deals. 

#### App:
The main web app will make use of modern web technologies such as WebSockets to make ads appear immediately after posted. In order to post an ad, a user will need to log in using an existing account like Facebook, Google, Twitter, or perhaps even an LiU-ID.

### Technological specification
#### Service:
The service will consist of a WebSocket-based bidirectional API using JSON for data transfer. This will prepare Bullet to be implemented as a native app for iOS or Android in the future. The WAMP standard (Web Application Messaging Protocol) will probably be used. 

Since multiple external login services are needed, the internal authentication against these will use OAuth 2.0. An internal account will be created the first time a user logs in, e.g. calls a specific remote login procedure over the socket connection

The server will also act as a web server and will be written in Google’s new Dart language. Since the focus is on supplying an API, the web server part will be very light, only serving the static resources needed by the web app. For this reason, no specific framework is needed, since Dart already provides the nessesary functionality through libraries. 

For object persistence, an object mapper called Objectory will be used which stores objects in MongoDB, a NoSQL database. This is mainly because there is no ORM mapping for Dart as of yet. I am also curious to try out a NoSQL approach.

#### App:
The main app will be a Single-Page App (SPA) also written in Dart. It will make use of the framework Angular.dart, which is an official port of Angular.js for Dart. The web app will adapt the content displayed to the device’s display size. Such a responsive UI will need a CSS framework such as Bootstrap or Pure.

#### Testing:
Since both the backend and frontend are written in Dart, unit tests will be carried out using Dart’s unittest library.