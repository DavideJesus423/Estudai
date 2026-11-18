# Estudaí API — autenticação

Backend independente em Python/FastAPI para cadastro, login, renovação de sessão, logout e consulta do usuário autenticado. Foi modelado para o dump `estudai_dbr` fornecido no projeto.

## Compatibilidade com o banco existente

A API utiliza somente as tabelas `users` e `user_sessions` já existentes. Não executa `create_all`, não apaga tabelas e não cria um segundo cadastro de usuários.

Campos utilizados em `users`:
- `id`, `name`, `email`, `password_hash`, `profile_photo`, `status`, `created_at`.
- `status` precisa ser `active` para autenticar.
- `password_hash` recebe o hash Argon2id, nunca a senha original.

Campos utilizados em `user_sessions`:
- `user_id`, `refresh_token_hash`, `expires_at`, `revoked_at`, `created_at`.
- O refresh token original só é entregue ao aplicativo. No banco fica seu SHA-256.

O dump não inclui migração para alterar o schema. A API assume que as tabelas estão criadas como no dump MySQL 8.0.45.

## Requisitos

- Python 3.11 ou superior.
- MySQL 8 com o banco `estudai_dbr` restaurado.
- Usuário MySQL próprio para a API, com permissões mínimas de `SELECT`, `INSERT`, `UPDATE` em `users` e `user_sessions`.
- Flutter/Dart no aplicativo.

## Instalação local (Windows PowerShell)

Na pasta `backend`:

```powershell
py -3.11 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edite `.env`. Gere um segredo JWT aleatório, por exemplo:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Coloque o resultado em `JWT_SECRET`. Não publique `.env` no GitHub.

Exemplo de `DATABASE_URL`:

```text
mysql+pymysql://estudai_api:SENHA_URL_ENCODED@127.0.0.1:3306/estudai_dbr?charset=utf8mb4
```

Se a senha tiver caracteres especiais (`@`, `#`, `/`, `%`), faça URL-encode antes de inseri-la na URL.

Inicie:

```powershell
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Documentação interativa:
- http://127.0.0.1:8000/docs
- http://127.0.0.1:8000/redoc
- Verificação simples: http://127.0.0.1:8000/health

## Criar usuário MySQL da API

Execute no DBeaver conectado como administrador. Troque a senha por uma forte:

```sql
CREATE USER 'estudai_api'@'localhost' IDENTIFIED BY 'TROQUE_POR_UMA_SENHA_FORTE';
GRANT SELECT, INSERT, UPDATE ON estudai_dbr.users TO 'estudai_api'@'localhost';
GRANT SELECT, INSERT, UPDATE ON estudai_dbr.user_sessions TO 'estudai_api'@'localhost';
FLUSH PRIVILEGES;
```

Se a API rodar em outro computador/container, o host autorizado e a rede precisam ser ajustados. Não exponha a porta 3306 publicamente; prefira rede privada/firewall.

## Endpoints

Prefixo: `/api/v1`

### `POST /auth/register`

Entrada:

```json
{
  "name": "Nome Sobrenome",
  "email": "aluno@example.com",
  "password": "uma-senha-forte"
}
```

Cria o usuário e inicia uma sessão. Retorna `201`.

### `POST /auth/login`

```json
{
  "email": "aluno@example.com",
  "password": "uma-senha-forte"
}
```

Retorna `200` com tokens e dados básicos do usuário.

### `POST /auth/refresh`

```json
{
  "refresh_token": "TOKEN_RECEBIDO_NO_LOGIN"
}
```

Revoga o refresh token anterior e emite outro. O aplicativo deve substituir os dois tokens armazenados pelos novos.

### `POST /auth/logout`

```json
{
  "refresh_token": "TOKEN_ATUAL"
}
```

Revoga a sessão. Retorna `204`.

### `GET /auth/me`

Cabeçalho:

```text
Authorization: Bearer ACCESS_TOKEN
```

Retorna os dados básicos do usuário autenticado.

### Resposta de autenticação

```json
{
  "token_type": "bearer",
  "access_token": "...",
  "refresh_token": "...",
  "expires_in": 900,
  "user": {
    "id": 1,
    "name": "Nome Sobrenome",
    "email": "aluno@example.com",
    "profile_photo": null,
    "status": "active",
    "created_at": "2026-11-11T12:00:00"
  }
}
```

## Como a autenticação funciona

1. O Flutter envia nome/e-mail/senha por HTTPS para a API.
2. A API valida os dados e verifica se o e-mail já existe.
3. A senha é processada pelo Argon2id. O resultado, e não a senha, vai para `users.password_hash`.
4. A API cria um refresh token aleatório e salva somente o SHA-256 dele em `user_sessions`.
5. A API devolve access token JWT (15 minutos por padrão) e refresh token (30 dias por padrão).
6. O Flutter envia o access token no cabeçalho `Authorization` para rotas protegidas.
7. Quando o access token expira, o Flutter chama `/auth/refresh`, salva os tokens novos e repete a requisição original uma única vez.
8. No logout, o Flutter chama `/auth/logout` e apaga os tokens locais.

## Integração com Flutter

Adicione dependências:

```yaml
dependencies:
  http: ^1.2.2
  flutter_secure_storage: ^9.2.2
```

Implemente o contrato existente `lib/features/auth/auth_repository.dart`. A implementação precisa receber também `name` no método `signUpWithEmail`, pois a coluna `users.name` é obrigatória no banco.

Exemplo reduzido do cliente HTTP (crie `lib/core/api/estudai_api.dart`):

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EstudaiApi {
  EstudaiApi(this.baseUrl);
  final String baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['detail'] ?? 'Não foi possível concluir a operação.');
    }
    return data;
  }

  Future<void> saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access_token'] as String);
    await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await post('/auth/register', {
      'name': name, 'email': email, 'password': password,
    });
    await saveTokens(data);
    return data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await post('/auth/login', {'email': email, 'password': password});
    await saveTokens(data);
    return data['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh != null) {
      try { await post('/auth/logout', {'refresh_token': refresh}); } finally {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
      }
    } else {
      await _storage.deleteAll();
    }
  }
}
```

### Endereço do servidor no Flutter

- Emulador Android: `http://10.0.2.2:8000`
- iOS Simulator: `http://127.0.0.1:8000`
- Celular físico: `http://IP_LOCAL_DO_PC:8000` (PC e celular na mesma rede; liberar a porta 8000 no firewall apenas para a rede local).

Esses endereços são apenas para desenvolvimento. Em produção, use domínio com HTTPS. Não use `localhost` no celular físico: ele aponta para o próprio celular.

## Segurança e operação

- Nunca grave senha, access token ou refresh token em logs.
- Nunca coloque a senha do MySQL ou `JWT_SECRET` no Flutter.
- Use HTTPS em produção.
- Armazene tokens no `flutter_secure_storage`, não em `SharedPreferences`.
- Restrinja CORS aos domínios/origens realmente usados. CORS não substitui autenticação.
- A API não faz rate limit internamente. Em produção, configure limite por IP/rota no proxy (por exemplo, Nginx/API Gateway), monitoramento, backups e alertas.
- O access token JWT não é revogado imediatamente no logout; ele permanece válido até expirar (15 min por padrão). O refresh token é revogado no banco.
- Não existe promessa de 100% de disponibilidade: isso depende também da hospedagem, rede, banco, backups, observabilidade e redundância.

## Limites conhecidos desta primeira entrega

- Login Google/Apple ainda não está implementado, embora o banco tenha `auth_accounts`.
- Recuperação de senha ainda não está implementada. Não retorne sucesso fictício na tela.
- O endpoint de registro retorna tokens imediatamente; se o projeto exigir verificação de e-mail, isso deve ser adicionado antes de liberar acesso.
- O projeto usa SQLAlchemy síncrono com pool de conexões. É uma escolha simples e estável para a primeira versão; não significa que o sistema suporte carga ilimitada.
- O código não executa migrations nem cria tabelas. Restaure o dump antes de iniciar a API.

## Testes manuais mínimos

1. Cadastre usuário com nome, e-mail e senha.
2. Confirme no DBeaver que `users.password_hash` não contém a senha original.
3. Confirme que `user_sessions.refresh_token_hash` tem 64 caracteres hexadecimais.
4. Faça login com senha errada: deve retornar `401`.
5. Faça login com usuário bloqueado: deve retornar `403`.
6. Chame `/auth/me` com access token: deve retornar o usuário.
7. Renove o token; tente renovar novamente com o refresh anterior: deve retornar `401`.
8. Faça logout; tente renovar a sessão encerrada: deve retornar `401`.

Antes de publicar, execute testes automatizados, teste concorrência de refresh, teste em ambiente semelhante à produção e faça revisão de segurança.

## Geração de questões (IA)

`POST /api/v1/questions/generate` (exige `Authorization: Bearer ACCESS_TOKEN`), corpo `multipart/form-data`:

- `file`: PDF (até `MAX_PDF_MB`, padrão 10 MB; validado pelo cabeçalho `%PDF-`).
- `num_questions`: 1 a 20 (padrão 5).
- `num_options`: 2 a 5 (padrão 4).

Resposta `200`:

```json
{"questions": [{"statement": "...", "options": ["...", "..."], "correct_index": 1, "explanation": "..."}]}
```

Erros: `401` sem sessão, `413` PDF grande demais, `415` não é PDF, `422` parâmetros fora do intervalo, `502` falha ou resposta inválida da IA, `503` chave da IA não configurada.

Configuração no `.env`: `GEMINI_API_KEY` (chave do Google AI Studio; só no servidor, nunca no Flutter), `AI_MODEL` (padrão `gemini-2.5-flash`; confira o nome vigente e os limites gratuitos no Google AI Studio), `AI_FALLBACK_MODELS` (modelos reserva, separados por vírgula: se o principal der 503, 404 ou limite, a API tenta de novo e passa ao próximo; erros 503 são repetidos uma vez por modelo), `AI_TIMEOUT_SECONDS`. O PDF é enviado à API do Gemini e a resposta segue um JSON Schema, depois revalidada pelo backend. Nada do conteúdo do PDF vai para o log.

O plano gratuito do Gemini tem limite de requisições por minuto e por dia; ao estourar, a API devolve 502 com a mensagem de limite atingido. A API não tem limite de uso por usuário: configure rate limit no proxy antes de publicar.

Testes: `pytest` (usam um gerador falso, não chamam a IA). A chamada real à IA não foi testada.
