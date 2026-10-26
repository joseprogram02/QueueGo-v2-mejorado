import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import '../repositories/auth_repository.dart';

/// Implementación de autenticación utilizando Supabase.
///
/// SRP:
/// Esta clase se encarga exclusivamente de comunicarse
/// con Supabase Auth y obtener el rol del usuario.
///
/// DIP:
/// Implementa AuthRepository, por lo que la interfaz de usuario
/// no depende directamente de Supabase.
class SupabaseAuthService implements AuthRepository {
  final SupabaseClient _client;

  UserRole? _currentRole;

  SupabaseAuthService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  @override
  UserRole? get currentRole => _currentRole;

  @override
  Future<UserRole?> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;

    if (user == null) {
      return null;
    }

    final role = await _getUserRole(user.id);

    _currentRole = role;

    return role;
  }

  @override
  Future<UserRole?> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Por seguridad, solamente Cliente y Restaurante
    // pueden registrarse desde la aplicación.
    if (role != UserRole.client &&
        role != UserRole.restaurant) {
      throw Exception(
        'Este rol no puede registrarse desde la aplicación.',
      );
    }

    final roleValue = role == UserRole.client
        ? 'client'
        : 'restaurant';

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'role': roleValue,
      },
    );

    final user = response.user;

    if (user == null) {
      return null;
    }

    return role;
  }

  Future<UserRole?> _getUserRole(
    String userId,
  ) async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _roleFromString(
      response['role'] as String,
    );
  }

  UserRole? _roleFromString(
    String value,
  ) {
    switch (value) {
      case 'client':
        return UserRole.client;

      case 'restaurant':
        return UserRole.restaurant;

      case 'courier':
        return UserRole.courier;

      case 'central':
        return UserRole.central;

      default:
        return null;
    }
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();

    _currentRole = null;
  }
}