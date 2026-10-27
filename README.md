# Estuda — Flutter (Splash, Get Started, Login, cadastro e Início)

Estuda: app de estudos (PIE UniFACEMA) que envia PDFs e gera questões com IA.
Esta etapa entrega as 3 telas do Figma, a navegação entre elas, uma tela de cadastro (proposta) e a tela Início (biblioteca) com a mesma paleta.

## Como executar

Este pacote **não inclui as pastas `android/` e `ios/`** (geradas pelo Flutter).
Com o Flutter instalado (`flutter doctor` sem erros):

```bash
cd estuda
flutter create . --project-name estuda --org br.edu.unifacema --platforms android,ios
del test\widget_test.dart   # teste de exemplo gerado pelo flutter create
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter create .` na pasta existente só adiciona o que falta; não sobrescreve `lib/`, `pubspec.yaml` nem `test/`.
Se ele alterar o `pubspec.yaml`, confira que continuam lá `assets/images/` e a família `Inter`.

## Estrutura

```
lib/
  main.dart · app.dart
  core/
    theme/        cores medidas no Figma + tema (fonte Inter)
    routes/       rotas nomeadas (splash → get-started → login / sign-up)
    validators.dart
  features/
    splash/       SplashScreen (1,8 s e segue para Get Started)
    onboarding/   GetStartedScreen + StudyMaterialCard
    auth/         LoginScreen, SignUpScreen, AuthRepository (contrato)
    home/         HomeScreen (biblioteca de materiais)
    materials/    StudyMaterial + MaterialsRepository (hoje só demonstração)
  shared/widgets/ PrimaryButton, SocialButton, AppTextField, BackLabelButton, GoogleLogo
assets/ images/logo.png · fonts/Inter-*.ttf (licença OFL)
test/navigation_test.dart
```

Próximas funcionalidades entram como novas pastas em `features/`
(`materials/` para PDFs, `questions/` para geração, resolução e resultado)
e um cliente de API em `core/` ou `data/`.

## Dependências

Nenhuma além do SDK. Dev: `flutter_test` e `flutter_lints`.
Fonte Inter incluída como asset (sem `google_fonts`).

## Decisões onde o Figma não bastava

- **Cores**: medidas por amostragem das imagens (ver `app_colors.dart`).
- **Fonte**: o protótipo parece Inter; usei Inter.
- **Logo**: recortada do PNG da splash (baixa resolução). **Substitua `assets/images/logo.png` pelo arquivo original** (de preferência com fundo transparente, 2x/3x).
- **Botão "Entrar com e-mail"**: o Figma só mostra o estado desabilitado (cinza). Habilitado fica azul-escuro (`#04324C`), quando o e-mail é válido e a senha não está vazia.
- **"Back"**: mantido em inglês como no Figma; troque por "Voltar" se for engano do protótipo.
- **Ícone do Google**: aproximação desenhada em código; use o asset oficial antes de publicar.
- **Tela de cadastro**: não existe no Figma. `SignUpScreen` é uma **proposta** reutilizando os componentes do login (e-mail, senha, confirmar senha). "Começar agora" abre essa tela.
- **Splash**: duração fixa de 1,8 s (sem inicialização real ainda).

## Modo demonstração

Em builds de **debug**, Login e Cadastro mostram "Entrar em modo demonstração (sem conta)",
que abre a tela Início com materiais de exemplo (avisados na tela). Não aparece em release
(`kDebugMode`) e deve ser removido quando houver login real (`shared/widgets/demo_mode_button.dart`).
"Enviar material" ainda não faz nada: é a próxima etapa.

## Nome do app

Para o nome exibido no celular, ajuste após o `flutter create`:
`android/app/src/main/AndroidManifest.xml` → `android:label="Estuda"` e
`ios/Runner/Info.plist` → `CFBundleDisplayName` e `CFBundleName` = `Estuda`.

## Autenticação: o que ainda falta

Nada de autenticação é simulado. Todos os botões chamam `UnconfiguredAuthRepository`,
que avisa "ainda não está configurado". Para ativar, implemente `AuthRepository` e passe em `EstudaApp(authRepository: ...)`:

- **E-mail/senha e recuperação de senha**: escolher o serviço (ex.: Firebase Auth ou backend próprio).
- **Google**: projeto no Google Cloud/Firebase, OAuth client, SHA-1 (Android) e client ID/URL scheme (iOS).
- **Apple**: conta Apple Developer e capability "Sign in with Apple" (obrigatória na App Store se houver login social).

Senhas ficam só em memória nos campos e não são gravadas nem logadas. Chaves de API (IA) devem ficar no backend, como descrito no aporte teórico.

## Estado da verificação

Escrito sem executar: o ambiente onde foi gerado não tinha Flutter/Dart e não conseguia baixá-lo.
Nem `flutter analyze` nem `flutter test` foram rodados. Se aparecer erro de compilação ou overflow em algum tamanho de tela, me mande a saída.
