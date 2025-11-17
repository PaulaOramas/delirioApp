import 'package:flutter/material.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/search_screen.dart';
import 'package:delirio_app/screens/cart_screen.dart';
import 'package:delirio_app/screens/profile_screen.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/navigation.dart' as nav;

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
  void initState() {
    super.initState();
    nav.bottomNavIndex.addListener(_onNavIndexChanged);
  }

  @override
  void dispose() {
    nav.bottomNavIndex.removeListener(_onNavIndexChanged);
    super.dispose();
  }

  void _onNavIndexChanged() {
    setState(() {
      _currentIndex = nav.bottomNavIndex.value;
    });
  }

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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
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
                _buildNavItem(Icons.search, "Buscar", 1, theme),

                // 🛒 Carrito con badge
                ValueListenableBuilder<List<CartItem>>(
                  valueListenable: CartService().items,
                  builder: (context, items, _) {
                    final total = items.fold<int>(0, (s, it) => s + it.qty);
                    return _buildNavItemWithBadge(
                      Icons.shopping_cart,
                      "Carrito",
                      2,
                      theme,
                      total,
                    );
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

  // ===========================================================
  // ÍCONOS NORMALES CON TEXTO
  // ===========================================================
  Widget _buildNavItem(IconData icon, String label, int index, ThemeData theme) {
    final bool isActive = _currentIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => nav.bottomNavIndex.value = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isActive ? activeColor : inactiveColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  // ===========================================================
  // CARRITO CON BADGE + TEXTO
  // ===========================================================
  Widget _buildNavItemWithBadge(
    IconData icon,
    String label,
    int index,
    ThemeData theme,
    int badgeCount,
  ) {
    final bool isActive = _currentIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant;

    final baseIcon = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 26,
        color: isActive ? activeColor : inactiveColor.withOpacity(0.9),
      ),
    );

    return GestureDetector(
      onTap: () => nav.bottomNavIndex.value = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(key: nav.cartIconKey, child: baseIcon),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
