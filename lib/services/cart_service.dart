import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final String? imagen;
  int qty;

  String? dedicatoria;

  CartItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    this.imagen,
    this.qty = 1,
    this.dedicatoria,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'precio': precio,
        'imagen': imagen,
        'qty': qty,
        'dedicatoria': dedicatoria,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      precio: (json['precio'] as num).toDouble(),
      imagen: json['imagen'],
      qty: json['qty'],
      dedicatoria: json['dedicatoria'],
    );
  }
}

class CartService {
  CartService._internal();
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final ValueNotifier<List<CartItem>> items = ValueNotifier<List<CartItem>>([]);

  // ======================
  //     PERSISTENCIA
  // ======================

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.value.map((e) => e.toJson()).toList();
    await prefs.setString('cart_data', jsonEncode(data));
  }

  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart_data');

    if (raw == null) return;

    final List decoded = jsonDecode(raw);
    items.value = decoded.map((e) => CartItem.fromJson(e)).toList();
  }

  // ======================
  //     OPERACIONES
  // ======================

  void addItem(CartItem item) {
    final idx = items.value.indexWhere((i) => i.id == item.id);

    if (idx >= 0) {
      items.value[idx].qty += item.qty;
    } else {
      items.value = [...items.value, item];
    }

    items.notifyListeners();
    _saveToLocal();
  }

  void removeItem(int id) {
    items.value = items.value.where((i) => i.id != id).toList();
    items.notifyListeners();
    _saveToLocal();
  }

  void clear() {
    items.value = [];
    items.notifyListeners();
    _saveToLocal();
  }

  void updateQty(int id, int newQty) {
    final idx = items.value.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    items.value[idx].qty = newQty;
    items.notifyListeners();
    _saveToLocal();
  }

  // ==============================
  //     🔥 DEDICATORIA FIJA Y OK
  // ==============================

  void updateDedicatoria(int id, String? nueva) {
    final idx = items.value.indexWhere((i) => i.id == id);
    if (idx < 0) return;

    items.value[idx].dedicatoria = nueva;

    // 🔥 Esto fuerza a refrescar toda la UI
    items.value = List.from(items.value);

    _saveToLocal();
  }

  int get totalItems => items.value.fold(0, (sum, it) => sum + it.qty);
}
