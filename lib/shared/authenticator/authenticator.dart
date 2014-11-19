library bullet.authenticator;

import 'dart:async';

/**
 * An interface for an object that authenticates a user
 */
abstract class Authenticator {

  const Authenticator();

  /**
   * The specific ID identifying the user.
   */
  String get userId;


  /**
   * The user's name, not the username
   */
  String get userName;

  /**
   * The user's email address
   */
  String get email;

  /**
   * A string representation of the type of authenticator, e.g. FB
   */
  String get type;

  /**
   * Checks if authenticator is authorized.
   * Throws if not authorized.
   */
  Future authenticate();

  /**
   * Whether the authenticator has expired
   */
  bool get hasExpired;

  /**
   * Get a configuration for the authenticator.
   */
  Map get config;
}
