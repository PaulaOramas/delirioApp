import 'package:flutter/foundation.dart';

class CartItem {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final String? imagen;
  int qty;

  CartItem({required this.id, required this.nombre, required this.categoria, required this.precio, this.imagen, this.qty = 1});
}

class CartService {
  CartService._internal();
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final ValueNotifier<List<CartItem>> items = ValueNotifier<List<CartItem>>([]);

  void addItem(CartItem item) {
    // Si ya existe, incrementar qty
    final idx = items.value.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      items.value[idx].qty += item.qty;
      items.notifyListeners();
      return;
    }
    items.value = [...items.value, item];
  }

  void removeItem(int id) {
    items.value = items.value.where((i) => i.id != id).toList();
  }

  void clear() {
    items.value = [];
  }

  int get totalItems => items.value.fold(0, (sum, it) => sum + it.qty);
}
