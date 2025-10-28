import 'package:flutter/foundation.dart';

/// Notifier to control the selected index of the MainScaffold bottom navigation.
/// This lets other screens (e.g., Profile) request switching to the dashboard.
final ValueNotifier<int> bottomNavIndex = ValueNotifier<int>(0);
