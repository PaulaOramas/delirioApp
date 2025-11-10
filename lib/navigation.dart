import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Notifier to control the selected index of the MainScaffold bottom navigation.
/// This lets other screens (e.g., Profile) request switching to the dashboard.
final ValueNotifier<int> bottomNavIndex = ValueNotifier<int>(0);

/// Global key for the cart icon in the bottom navigation bar so other screens
/// can animate towards it.
final GlobalKey cartIconKey = GlobalKey();
