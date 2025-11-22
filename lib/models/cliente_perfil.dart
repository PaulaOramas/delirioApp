// lib/models/cliente_perfil.dart
class ClientePerfil {
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;
  final String telefono;
  final String usuario;
  final String? direccion;
  final String? avatar;


  ClientePerfil({
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.telefono,
    required this.usuario,
    this.direccion,
    this.avatar,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory ClientePerfil.fromJson(Map<String, dynamic> json) {
    return ClientePerfil(
      nombre:   (json['Nombre'] ?? '').toString(),
      apellido: (json['Apellido'] ?? '').toString(),
      cedula:   (json['Cedula'] ?? '').toString(),
      correo:   (json['Correo'] ?? '').toString(),
      telefono: (json['Telefono'] ?? '').toString(),
      usuario:  (json['Usuario'] ?? '').toString(),
      direccion:json['Direccion']?.toString(),
      avatar:   json['Avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'Nombre': nombre,
    'Apellido': apellido,
    'Cedula': cedula,
    'Correo': correo,
    'Telefono': telefono,
    'Usuario': usuario,
    if (direccion != null) 'Direccion': direccion,
    if (avatar != null) 'Avatar': avatar,
  };
}
