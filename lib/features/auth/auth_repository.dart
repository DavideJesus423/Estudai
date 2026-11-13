import '../../core/api/estudai_api_client.dart';

/// Erro exibido pelas telas de autenticação.
class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset({required String email});
  Future<void> signOut();
}

/// Implementação real de autenticação usando a API Python/FastAPI do Estudaí.
class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository({EstudaiApiClient api = const EstudaiApiClient()}) : _api = api;

  final EstudaiApiClient _api;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _api.login(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.register(name: name, email: email, password: password);
  }

  @override
  Future<void> signOut() => _api.logout();

  @override
  Future<void> signInWithApple() => Future.error(
        const AuthNotConfiguredException(
          'Login com Apple ainda não foi implementado no backend.',
        ),
      );

  @override
  Future<void> signInWithGoogle() => Future.error(
        const AuthNotConfiguredException(
          'Login com Google ainda não foi implementado no backend.',
        ),
      );

  @override
  Future<void> sendPasswordReset({required String email}) => Future.error(
        const AuthNotConfiguredException(
          'A recuperação de senha ainda não possui endpoint no backend.',
        ),
      );
}
