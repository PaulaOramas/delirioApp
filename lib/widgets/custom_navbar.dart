import 'package:flutter/material.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/search_screen.dart';
import 'package:delirio_app/screens/cart_screen.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/navigation.dart' as nav;
import 'package:delirio_app/screens/profile_screen.dart';
import 'package:delirio_app/theme.dart';

class CustomNavBar extends StatefulWidget {
  final Widget? child;
  const CustomNavBar({super.key, this.child});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SearchScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: widget.child ?? _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              // aspecto "flotante" y casi transparente usando el tema
              color: theme.colorScheme.surface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home, "Inicio", 0, theme),
                _buildSearchButton(theme),
                // Cart item with badge (listening to CartService)
                ValueListenableBuilder<List<CartItem>>(
                  valueListenable: CartService().items,
                  builder: (context, items, _) {
                    final total = items.fold<int>(0, (s, it) => s + it.qty);
                    return _buildNavItemWithBadge(Icons.shopping_cart, 'Carrito', 2, theme, total);
                  },
                ),
                _buildNavItem(Icons.person, "Perfil", 3, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, ThemeData theme) {
    final bool isActive = _currentIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : inactiveColor.withOpacity(0.9),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildSearchButton(ThemeData theme) {
    final bool isActive = _currentIndex == 1;
    final activeColor = theme.colorScheme.primary;
    final inactiveTextColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isActive ? 60 : 140, // cuando activo se contrae a solo el icono
        height: 60,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: isActive
              ? Icon(Icons.search, color: activeColor, size: 26)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, color: activeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Buscar",
                      style: TextStyle(
                        color: inactiveTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(IconData icon, String label, int index, ThemeData theme, int badgeCount) {
    final base = _buildNavItem(icon, label, index, theme);
    if (badgeCount <= 0) return base;
    // If this is the cart icon, wrap base in a container with the global key
    // so other screens can locate the cart's position for animations.
    final Widget anchoredBase = icon == Icons.shopping_cart
        ? Container(key: nav.cartIconKey, child: base)
        : base;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        anchoredBase,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(0.12),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
