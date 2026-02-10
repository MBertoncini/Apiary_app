import 'package:flutter/material.dart';

/// Global navigator key used for navigating from non-widget code
/// (e.g., ApiService on session expiry).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
