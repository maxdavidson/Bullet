library bullet.authenticator;

import 'dart:async';

/**
 * An interface for an object that authenticates a user
 */
abstract class Authenticator {

  /**
   * The specific ID identifying the user.
   */
  String get userId;

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