/// Roles disponibles dentro de QueueGo.
///
/// Mantener los roles como un tipo propio evita trabajar con
/// cadenas de texto dispersas como "cliente", "repartidor", etc.
///
/// Esto reduce errores y facilita extender el sistema.
enum UserRole {
  client,
  restaurant,
  courier,
  central,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.client:
        return 'Cliente';
      case UserRole.restaurant:
        return 'Restaurante';
      case UserRole.courier:
        return 'Repartidor';
      case UserRole.central:
        return 'Central';
    }
  }
}