// lib/models/cliente_perfil.dart
class ClientePerfil {
  final String nombre;
  final String apellido;
  final String cedula;
  final String correo;
  final String telefono;
  final String usuario;
  final String? foto;
  final String? direccion;

  ClientePerfil({
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.telefono,
    required this.usuario,
    this.foto,
    this.direccion,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Mapea exactamente el JSON que compartiste:
  /// {
  ///   "Nombre": "Paula",
  ///   "Apellido": "O",
  ///   "Cedula": "17517",
  ///   "Correo": "paula@gmail.com",
  ///   "Telefono": "09881",
  ///   "Usuario": "pau",
  ///   "Foto": "...",          // opcional
  ///   "Direccion": "..."      // opcional
  /// }
  factory ClientePerfil.fromJson(Map<String, dynamic> json) {
    return ClientePerfil(
      nombre:   (json['Nombre'] ?? '').toString(),
      apellido: (json['Apellido'] ?? '').toString(),
      cedula:   (json['Cedula'] ?? '').toString(),
      correo:   (json['Correo'] ?? '').toString(),
      telefono: (json['Telefono'] ?? '').toString(),
      usuario:  (json['Usuario'] ?? '').toString(),
      foto:     json['Foto']?.toString(),
      direccion:json['Direccion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'Nombre': nombre,
    'Apellido': apellido,
    'Cedula': cedula,
    'Correo': correo,
    'Telefono': telefono,
    'Usuario': usuario,
    if (foto != null) 'Foto': foto,
    if (direccion != null) 'Direccion': direccion,
  };
}
