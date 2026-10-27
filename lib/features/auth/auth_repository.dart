/// Lançada quando um método de autenticação ainda não tem serviço real
/// configurado. A interface mostra [message] ao usuário.
class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException(this.message);

  final String message;

  @override
  String toString() => 'AuthNotConfiguredException: $message';
}

/// Contrato de autenticação. Implemente com o serviço escolhido
/// (ex.: Firebase Auth ou backend próprio) e injete em `EstudaApp`.
///
/// Importante: senhas só devem trafegar por HTTPS até o serviço de
/// autenticação; o app nunca as grava em disco nem em logs.
abstract class AuthRepository {
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Requer: conta Apple Developer + capability "Sign in with Apple".
  Future<void> signInWithApple();

  /// Requer: projeto no Google Cloud/Firebase com OAuth client
  /// (Android: SHA-1; iOS: client ID e URL scheme).
  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset({required String email});
}

/// Implementação padrão: nada está configurado, então nada "funciona".
/// Evita simular um login bem-sucedido.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) =>
      Future.error(const AuthNotConfiguredException(
          'Login por e-mail ainda não está configurado.'));

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      Future.error(const AuthNotConfiguredException(
          'Cadastro ainda não está configurado.'));

  @override
  Future<void> signInWithApple() => Future.error(
      const AuthNotConfiguredException('Login com Apple ainda não está configurado.'));

  @override
  Future<void> signInWithGoogle() => Future.error(
      const AuthNotConfiguredException('Login com Google ainda não está configurado.'));

  @override
  Future<void> sendPasswordReset({required String email}) => Future.error(
      const AuthNotConfiguredException(
          'Recuperação de senha ainda não está configurada.'));
}
