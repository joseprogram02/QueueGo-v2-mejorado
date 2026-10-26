import '../models/user_role.dart';

/// Contrato para las operaciones de autenticación.
///
/// DIP:
/// Las pantallas dependen de esta abstracción
/// y no directamente de Supabase.
abstract class AuthRepository {
  Future<UserRole?> login({required String email, required String password});

  Future<UserRole?> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();

  UserRole? get currentRole;
}
