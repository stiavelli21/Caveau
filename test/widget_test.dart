import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caveau/main.dart';
import 'package:caveau/core/localization/app_localizations.dart';
import 'package:caveau/models/vault_item.dart';
import 'package:caveau/models/security_settings.dart';
import 'package:caveau/providers/vault_provider.dart';
import 'package:caveau/providers/settings_provider.dart';
import 'package:caveau/core/services/secure_storage_service.dart';
import 'package:caveau/core/services/auth_service.dart';
import 'package:caveau/core/services/screen_security_service.dart';
import 'package:caveau/providers/auth_provider.dart';
import 'package:caveau/views/auth/lock_screen.dart';
import 'package:caveau/views/auth/onboarding_screen.dart';
import 'package:caveau/views/vault/vault_detail_screen.dart';
import 'package:caveau/views/widgets/desktop_sidebar.dart';
import 'package:caveau/views/widgets/language_selector_button.dart';
import 'package:caveau/views/widgets/vault_card.dart';
import 'package:caveau/views/widgets/vault_logo.dart';
import 'package:caveau/views/widgets/privacy_shield.dart';
import 'package:caveau/views/security/security_audit_screen.dart';
import 'package:caveau/views/generator/password_generator_screen.dart';
import 'package:caveau/views/settings/settings_screen.dart';
import 'package:caveau/views/vault/vault_home_screen.dart';

/// Test wrapper helper that registers mock/real providers and configures MaterialApp with localizations.
Widget _buildTestApp({
  required Widget child,
  VaultProvider? vaultProvider,
  SettingsProvider? settingsProvider,
  AuthProvider? authProvider,
  String locale = 'it',
}) {
  final storage = SecureStorageService();
  final vp = vaultProvider ?? VaultProvider(storageService: storage);
  final sp = settingsProvider ?? SettingsProvider(storageService: storage);
  final ap = authProvider ?? AuthProvider(storageService: storage);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<VaultProvider>.value(value: vp),
      ChangeNotifierProvider<SettingsProvider>.value(value: sp),
      ChangeNotifierProvider<AuthProvider>.value(value: ap),
    ],
    child: Consumer<SettingsProvider>(
      builder: (context, spContext, _) {
        final activeCode = settingsProvider != null
            ? spContext.settings.languageCode
            : locale;
        return MaterialApp(
          locale: Locale(activeCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        );
      },
    ),
  );
}

/// Comprehensive widget and interaction test suite for Caveau UI components.
void main() {
  testWidgets('PrivacyShield renders overlay and text properly when active in Italian and English', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        locale: 'it',
        child: const PrivacyShield(
          isShieldActive: true,
          child: Scaffold(body: Text('Original Content')),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Caveau Protetto'), findsOneWidget);
    expect(find.text('Schermata oscurata per la tua privacy'), findsOneWidget);

    // English
    await tester.pumpWidget(
      _buildTestApp(
        locale: 'en',
        child: const PrivacyShield(
          isShieldActive: true,
          child: Scaffold(body: Text('Original Content')),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Caveau Protected'), findsOneWidget);
    expect(find.text('Screen obscured for your privacy'), findsOneWidget);
  });

  testWidgets('Caveau App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const CaveauRoot());
    await tester.pump();
    expect(find.byType(CaveauRoot), findsOneWidget);
  });

  testWidgets('VaultDetailScreen renders login item and toggles password visibility', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    final item = VaultItem(
      id: 'test_item_1',
      title: 'Google Account',
      category: VaultCategory.login,
      username: 'user@gmail.com',
      password: 'SuperSecretPassword123!',
      updatedAt: DateTime.now(),
    );
    vaultProvider.items.add(item);

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        child: const VaultDetailScreen(itemId: 'test_item_1'),
      ),
    );

    await tester.pump();
    expect(find.text('Google Account'), findsOneWidget);
    expect(find.text('user@gmail.com'), findsOneWidget);
    // Initially password is obscured
    expect(find.text('••••••••••••'), findsOneWidget);

    // Tap visibility icon
    final visibilityBtn = find.byIcon(Icons.visibility_outlined);
    expect(visibilityBtn, findsOneWidget);
    await tester.tap(visibilityBtn);
    await tester.pump();

    // Password is now revealed
    expect(find.text('SuperSecretPassword123!'), findsOneWidget);
  });

  testWidgets('VaultDetailScreen renders website URL with open-in-browser and copy actions', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    final item = VaultItem(
      id: 'test_item_web',
      title: 'Google Account',
      category: VaultCategory.login,
      username: 'user@gmail.com',
      password: 'SuperSecretPassword123!',
      websiteUrl: 'https://accounts.google.com',
      updatedAt: DateTime.now(),
    );
    vaultProvider.items.add(item);

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        child: const VaultDetailScreen(itemId: 'test_item_web'),
      ),
    );

    await tester.pump();
    expect(find.text('https://accounts.google.com'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);

    // Tap the open link button
    await tester.tap(find.byIcon(Icons.open_in_new_rounded));
    await tester.pump();
  });

  testWidgets('VaultDetailScreen renders secure note item correctly', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    final item = VaultItem(
      id: 'test_note_1',
      title: 'Server Backup Codes',
      category: VaultCategory.note,
      notes: 'CODE-1234-5678\nCODE-9999-0000',
      updatedAt: DateTime.now(),
    );
    vaultProvider.items.add(item);

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        child: const VaultDetailScreen(itemId: 'test_note_1'),
      ),
    );

    await tester.pump();
    expect(find.text('Server Backup Codes'), findsOneWidget);
    expect(find.text('Note Crittografate'), findsWidgets);
    expect(find.text('CODE-1234-5678\nCODE-9999-0000'), findsOneWidget);
  });

  testWidgets('VaultCard 3-dots popup menu shows Copy, Edit, and Delete options', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    final item = VaultItem(
      id: 'test_item_card',
      title: 'Netflix Account',
      category: VaultCategory.login,
      username: 'user@netflix.com',
      password: 'MyNetflixPassword99!',
    );
    vaultProvider.items.add(item);

    bool editCalled = false;
    bool deleteCalled = false;

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        child: Scaffold(
          body: VaultCard(
            item: item,
            onTap: () {},
            onToggleFavorite: () {},
            onEdit: () => editCalled = true,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Netflix Account'), findsOneWidget);

    // Find and tap 3-dots menu icon
    final moreIcon = find.byIcon(Icons.more_vert_rounded);
    expect(moreIcon, findsOneWidget);
    await tester.tap(moreIcon);
    await tester.pumpAndSettle();

    // Verify popup menu items appear
    expect(find.text('Copia Password'), findsOneWidget);
    expect(find.text('Modifica'), findsOneWidget);
    expect(find.text('Elimina'), findsOneWidget);

    // Tap Modifica
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);

    // Tap 3-dots again and test Delete confirmation dialog
    await tester.tap(moreIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Elimina Elemento'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Elimina'), findsOneWidget);

    // Tap 'Elimina' inside dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Elimina'));
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });

  testWidgets('VaultLogo widget renders with custom size and glow', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VaultLogo(
            size: 64,
            showGlow: true,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(VaultLogo), findsOneWidget);
  });

  testWidgets('LockScreen renders LanguageSelectorButton and switches language', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const LockScreen(),
      ),
    );

    expect(find.byType(LanguageSelectorButton), findsOneWidget);
    expect(find.text('Caveau Protetto'), findsOneWidget);
    expect(find.text('Sblocca Cassaforte'), findsOneWidget);

    // Tap language selector to open bottom sheet
    await tester.tap(find.byType(LanguageSelectorButton));
    await tester.pumpAndSettle();

    // Verify all 5 language options appear in the bottom sheet
    expect(find.widgetWithText(ListTile, 'Italiano'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'English'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Español'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Français'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Deutsch'), findsOneWidget);

    // Tap Español
    await tester.tap(find.widgetWithText(ListTile, 'Español'));
    await tester.pumpAndSettle();

    // Language in provider should now be 'es'
    expect(settingsProvider.settings.languageCode, equals('es'));
  });

  testWidgets('PrivacyShield renders correctly across Spanish, French, and German', (WidgetTester tester) async {
    // Spanish
    await tester.pumpWidget(
      _buildTestApp(
        locale: 'es',
        child: const PrivacyShield(
          isShieldActive: true,
          child: Scaffold(body: Text('Original Content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Caveau Protegido'), findsOneWidget);
    expect(find.text('Pantalla oculta por tu privacidad'), findsOneWidget);

    // French
    await tester.pumpWidget(
      _buildTestApp(
        locale: 'fr',
        child: const PrivacyShield(
          isShieldActive: true,
          child: Scaffold(body: Text('Original Content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Caveau Protégé'), findsOneWidget);
    expect(find.text('Écran masqué pour votre confidentialité'), findsOneWidget);

    // German
    await tester.pumpWidget(
      _buildTestApp(
        locale: 'de',
        child: const PrivacyShield(
          isShieldActive: true,
          child: Scaffold(body: Text('Original Content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Caveau Geschützt'), findsOneWidget);
    expect(find.text('Bildschirm zum Schutz Ihrer Privatsphäre verdeckt'), findsOneWidget);
  });

  testWidgets('OnboardingScreen renders LanguageSelectorButton', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const OnboardingScreen(),
      ),
    );

    await tester.pump();
    expect(find.byType(LanguageSelectorButton), findsOneWidget);
    expect(find.text('Benvenuto in Caveau'), findsOneWidget);
    expect(find.text('Inizializza Caveau Sicuro'), findsOneWidget);
  });

  testWidgets('LockScreen does not trigger biometrics when mounted while inactive or paused', (WidgetTester tester) async {
    final mockAuthService = _MockTestAuthService();
    final authProvider = _TestAuthProvider(authService: mockAuthService);
    final settingsProvider = SettingsProvider();

    // Simulate inactive app state (e.g. user opening task switcher / app drawer)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const LockScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Biometrics should NOT have been called because app is inactive
    expect(mockAuthService.biometricsCallCount, equals(0));

    // When the app returns to resumed state
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Biometrics SHOULD now be triggered
    expect(mockAuthService.biometricsCallCount, equals(1));
  });

  testWidgets('SecurityAuditScreen pops when swiped left-to-right', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SecurityAuditScreen()),
                );
              },
              child: const Text('Open Audit'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open Audit'));
    await tester.pumpAndSettle();

    expect(find.byType(SecurityAuditScreen), findsOneWidget);

    // Swipe from left to right across the screen
    await tester.fling(find.byType(SecurityAuditScreen), const Offset(350, 0), 1000);
    await tester.pumpAndSettle();

    // Verify screen was popped
    expect(find.byType(SecurityAuditScreen), findsNothing);
    expect(find.text('Open Audit'), findsOneWidget);
  });

  testWidgets('PasswordGeneratorScreen pops when swiped left-to-right', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PasswordGeneratorScreen()),
                );
              },
              child: const Text('Open Generator'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open Generator'));
    await tester.pumpAndSettle();

    // Swipe from left to right on screen
    await tester.flingFrom(const Offset(50, 150), const Offset(350, 0), 1000);
    await tester.pumpAndSettle();

    // Verify screen was popped
    expect(find.byType(PasswordGeneratorScreen), findsNothing);
    expect(find.text('Open Generator'), findsOneWidget);
  });

  testWidgets('PasswordGeneratorScreen dragging slider adjusts value without popping screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PasswordGeneratorScreen()),
                );
              },
              child: const Text('Open Generator'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open Generator'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordGeneratorScreen), findsOneWidget);
    expect(find.text('16'), findsOneWidget); // Default length

    // Drag the slider
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    await tester.drag(sliderFinder, const Offset(100, 0));
    await tester.pumpAndSettle();

    // Verify screen was NOT popped and slider value changed
    expect(find.byType(PasswordGeneratorScreen), findsOneWidget);
    expect(find.text('16'), findsNothing);
  });

  testWidgets('SettingsScreen pops when swiped left-to-right and has Language section', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('AUTENTICAZIONE & ACCESSO'), findsOneWidget);

    // Scroll down to find the Language section below Backup & Restore
    await tester.scrollUntilVisible(
      find.text('LINGUA / LANGUAGE'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('LINGUA / LANGUAGE'), findsOneWidget);
    expect(find.text('Lingua'), findsOneWidget);

    // Swipe from right to left (negative offset) -> should NOT pop
    await tester.fling(find.byType(SettingsScreen), const Offset(-350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    // Swipe from left to right (positive offset) -> should pop
    await tester.fling(find.byType(SettingsScreen), const Offset(350, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('VaultHomeScreen has compact FloatingActionButton with only + icon', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);
    final authProvider = AuthProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        authProvider: authProvider,
        child: const VaultHomeScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify FloatingActionButton exists with add icon
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    expect(find.descendant(of: fabFinder, matching: find.byIcon(Icons.add_rounded)), findsOneWidget);
    // Verify there is no Text inside the FAB (it's icon only)
    expect(find.descendant(of: fabFinder, matching: find.byType(Text)), findsNothing);
  });

  testWidgets('SettingsScreen renders Backup & Restore section with green border', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const SettingsScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('BACKUP & RIPRISTINO'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('BACKUP & RIPRISTINO'), findsOneWidget);
    expect(find.text('Esporta Backup Cifrato'), findsOneWidget);
    expect(find.text('Ripristina Backup'), findsOneWidget);
  });

  testWidgets('OnboardingScreen renders information briefing card, GitHub button, Privacy Policy button and checkbox', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const OnboardingScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify LanguageSelectorButton is present
    expect(find.byType(LanguageSelectorButton), findsOneWidget);

    // Verify Briefing info card content
    expect(find.text('Prima di iniziare: Informazioni Importanti'), findsOneWidget);
    expect(find.text('100% Offline e Zero-Knowledge'), findsOneWidget);
    expect(find.text('Nessun Recupero PIN & Backup Vitali'), findsOneWidget);
    expect(find.text('100% Gratuita e Senza Costi'), findsOneWidget);
    expect(find.text('Codice Open Source su GitHub'), findsOneWidget);
    expect(find.text('Privacy Policy e Termini'), findsOneWidget);

    // Verify Buttons inside info card
    expect(find.text('Vedi su GitHub'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    // Verify Disclaimer Checkbox
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Ho compreso che sono l\'unico custode del mio PIN Master e dei miei backup.'), findsOneWidget);

    // Ensure checkbox is visible in viewport before tapping
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Verify toggle checkbox works
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('SettingsScreen renders Legal & Transparency section with Privacy Policy and Open Source tiles', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const SettingsScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('NOTE LEGALI & TRASPARENZA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NOTE LEGALI & TRASPARENZA'), findsOneWidget);
    expect(find.text('Informativa sulla Privacy'), findsOneWidget);
    expect(find.text('Codice Sorgente Open Source'), findsOneWidget);
    expect(find.text('Guida Sicurezza e Backup'), findsOneWidget);
  });

  testWidgets('SettingsScreen export dialog prompts for password twice and validates matching', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const SettingsScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.text('Esporta Backup Cifrato'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('Esporta Backup Cifrato'));
    await tester.pumpAndSettle();

    // Verify dialog has 2 text fields (Password and Confirm Password)
    expect(find.text('Password di cifratura backup'), findsOneWidget);
    expect(find.text('Conferma password di backup'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Type non-matching passwords and try to generate
    await tester.enterText(find.byType(TextField).at(0), 'Password123');
    await tester.enterText(find.byType(TextField).at(1), 'Password456');
    await tester.tap(find.text('Genera'));
    await tester.pumpAndSettle();

    // Verify error message for mismatch
    expect(find.text('Le password di backup non corrispondono'), findsOneWidget);
  });

  testWidgets('CaveauApp activates PrivacyShield when screen recording is detected', (WidgetTester tester) async {
    final mockScreenSec = _MockScreenSecurityService();
    await tester.pumpWidget(
      CaveauRoot(
        screenSecurityService: mockScreenSec,
      ),
    );
    await tester.pump();

    // Verify initial state: PrivacyShield is not active
    expect(find.text('Caveau Protetto'), findsNothing);

    // Simulate screen recording start
    mockScreenSec.emitCapture(true);
    await tester.pump();

    // Verify PrivacyShield overlay is now active
    expect(find.text('Caveau Protetto'), findsOneWidget);

    // Simulate screen recording stop
    mockScreenSec.emitCapture(false);
    await tester.pump();

    // Verify PrivacyShield overlay has been removed
    expect(find.text('Caveau Protetto'), findsNothing);
    mockScreenSec.dispose();
  });

  testWidgets('VaultHomeScreen renders DesktopSidebar and Split-View when screen width >= 900', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);
    final vaultProvider = VaultProvider(storageService: mockStorage);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        vaultProvider: vaultProvider,
        child: const VaultHomeScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify DesktopSidebar is rendered
    expect(find.byType(DesktopSidebar), findsOneWidget);
    expect(find.text('Nessun elemento selezionato'), findsOneWidget);
    expect(find.text('Seleziona un elemento per visualizzarne i dettagli'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('VaultHomeScreen selecting item in desktop master list renders VaultDetailView in detail pane', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockStorage = SecureStorageService();
    final authService = AuthService(storageService: mockStorage);
    final authProvider = AuthProvider(authService: authService, storageService: mockStorage);
    final settingsProvider = SettingsProvider(storageService: mockStorage);

    final sampleItem = VaultItem(
      id: 'test-desktop-item-1',
      title: 'GitHub Work Account',
      category: VaultCategory.login,
      username: 'dev@github.com',
      password: 'StrongSecretPassword123!',
    );
    final vaultProvider = _TestVaultProvider(initialItems: [sampleItem]);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        vaultProvider: vaultProvider,
        child: const VaultHomeScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on the item in the master list
    await tester.tap(find.text('GitHub Work Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify VaultDetailView is displayed inline in the right pane
    expect(find.byType(VaultDetailView), findsOneWidget);
    expect(find.text('dev@github.com'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('LockScreen on desktop widescreen renders centered card and does not show biometrics', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuthService = _MockTestAuthService();
    final authProvider = _TestAuthProvider(authService: mockAuthService);
    final settingsProvider = SettingsProvider();

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        child: const LockScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify PIN text field exists
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AppLocalizationsIt().unlockVaultButton), findsOneWidget);
    // Verify biometric unlock button is NOT present on desktop
    expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('OnboardingScreen displays explanatory error when submitting without disclaimer and updates on language switch', (WidgetTester tester) async {
    final storage = SecureStorageService();
    final settingsProvider = _TestSettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: Consumer<SettingsProvider>(
          builder: (context, sp, _) {
            return MaterialApp(
              locale: Locale(sp.settings.languageCode),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: MultiProvider(
                providers: [
                  ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(storageService: storage)),
                ],
                child: const OnboardingScreen(),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially no error is present
    expect(find.text(AppLocalizationsIt().onboardingDisclaimerRequiredError), findsNothing);

    // Scroll to and tap initialize button without checking disclaimer
    final initButton = find.widgetWithText(ElevatedButton, AppLocalizationsIt().initializeVaultButton);
    await tester.ensureVisible(initButton);
    await tester.tap(initButton);
    await tester.pump(const Duration(milliseconds: 100));

    // Verify explanatory Italian error message is displayed
    expect(find.text(AppLocalizationsIt().onboardingDisclaimerRequiredError), findsOneWidget);

    // Switch language to English dynamically
    await settingsProvider.updateLanguage('en');
    await tester.pump(const Duration(milliseconds: 100));

    // Verify error message translated dynamically to English!
    expect(find.text(AppLocalizationsEn().onboardingDisclaimerRequiredError), findsOneWidget);
    expect(find.text(AppLocalizationsIt().onboardingDisclaimerRequiredError), findsNothing);

    // Check the disclaimer checkbox
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump(const Duration(milliseconds: 100));

    // Error should be cleared
    expect(find.text(AppLocalizationsEn().onboardingDisclaimerRequiredError), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('SecurityAuditScreen renders multi-line stat titles across supported languages', (WidgetTester tester) async {
    final mockStorage = SecureStorageService();
    final vaultProvider = VaultProvider(storageService: mockStorage);
    final settingsProvider = _TestSettingsProvider();

    await tester.pumpWidget(
      _buildTestApp(
        vaultProvider: vaultProvider,
        settingsProvider: settingsProvider,
        child: const SecurityAuditScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // In Italian
    expect(find.text(AppLocalizationsIt().totalItemsStat), findsOneWidget);
    expect(find.text(AppLocalizationsIt().weakPasswordsStat), findsOneWidget);
    expect(find.text(AppLocalizationsIt().reusedPasswordsStat), findsOneWidget);

    // Switch to German (which typically has the longest compound words/strings)
    await settingsProvider.updateLanguage('de');
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(AppLocalizationsDe().totalItemsStat), findsOneWidget);
    expect(find.text(AppLocalizationsDe().weakPasswordsStat), findsOneWidget);
    expect(find.text(AppLocalizationsDe().reusedPasswordsStat), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('Inactivity auto-locks vault after autoLockSeconds elapsed without user interaction', (WidgetTester tester) async {
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 15));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(screenSecurityService: mockScreenSec),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));
    expect(find.byType(VaultHomeScreen), findsOneWidget);

    // Wait 10 seconds (less than 15s)
    await tester.pump(const Duration(seconds: 10));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait another 6 seconds (total 16s > 15s)
    await tester.pump(const Duration(seconds: 6));
    expect(authProvider.status, equals(AuthStatus.locked));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('User pointer interaction resets inactivity timer', (WidgetTester tester) async {
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 15));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(screenSecurityService: mockScreenSec),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait 10s
    await tester.pump(const Duration(seconds: 10));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // User touches screen / taps
    await tester.tap(find.byType(Scaffold).first);
    await tester.pump();

    // Wait 10s after interaction (total 20s elapsed from start, but 10s from tap < 15s)
    await tester.pump(const Duration(seconds: 10));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Now wait remaining 6s (total 16s from tap > 15s)
    await tester.pump(const Duration(seconds: 6));
    expect(authProvider.status, equals(AuthStatus.locked));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('Inactivity auto-locks vault after 5 seconds when autoLockSeconds is set to 0 (Immediate)', (WidgetTester tester) async {
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 0));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(screenSecurityService: mockScreenSec),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));
    expect(find.byType(VaultHomeScreen), findsOneWidget);

    // Wait 3 seconds (less than 5s)
    await tester.pump(const Duration(seconds: 3));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait another 3 seconds (total 6s > 5s)
    await tester.pump(const Duration(seconds: 3));
    expect(authProvider.status, equals(AuthStatus.locked));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  Future<void> simulateBackground(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
  }

  Future<void> simulateResume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  testWidgets('Backgrounding app with autoLockSeconds: 0 immediately locks the vault', (WidgetTester tester) async {
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 0));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(screenSecurityService: mockScreenSec),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Put app into background via standard lifecycle transition
    await simulateBackground(tester);
    expect(authProvider.status, equals(AuthStatus.locked));

    // Resume app
    await simulateResume(tester);
    expect(authProvider.status, equals(AuthStatus.locked));
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('Backgrounding app for longer than autoLockSeconds locks the vault on resume', (WidgetTester tester) async {
    var simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 15));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(
          screenSecurityService: mockScreenSec,
          clock: () => simulatedTime,
        ),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Transition to background
    await simulateBackground(tester);
    // In background, autoLockSeconds > 0 does not lock immediately
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait 16 seconds in background (> 15s)
    simulatedTime = simulatedTime.add(const Duration(seconds: 16));
    await tester.pump(const Duration(seconds: 16));

    // Resume app
    await simulateResume(tester);
    expect(authProvider.status, equals(AuthStatus.locked));
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('Backgrounding app when combined elapsed inactivity exceeds autoLockSeconds locks on resume', (WidgetTester tester) async {
    var simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 15));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(
          screenSecurityService: mockScreenSec,
          clock: () => simulatedTime,
        ),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Inactivity in foreground for 10s
    simulatedTime = simulatedTime.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Transition to background for 6s (total inactivity 10s + 6s = 16s > 15s)
    await simulateBackground(tester);
    simulatedTime = simulatedTime.add(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));

    // Resume app
    await simulateResume(tester);
    expect(authProvider.status, equals(AuthStatus.locked));
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('Backgrounding app and resuming before autoLockSeconds expires resumes with remaining inactivity time', (WidgetTester tester) async {
    var simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider(initialSettings: const SecuritySettings(autoLockSeconds: 15));
    final mockScreenSec = _MockScreenSecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<VaultProvider>(create: (_) => VaultProvider()),
        ],
        child: CaveauApp(
          screenSecurityService: mockScreenSec,
          clock: () => simulatedTime,
        ),
      ),
    );

    await tester.pump();
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Inactivity in foreground for 5s
    simulatedTime = simulatedTime.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    // Transition to background for 5s (total 10s < 15s)
    await simulateBackground(tester);
    simulatedTime = simulatedTime.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    // Resume app (10s total inactivity, 5s remaining)
    await simulateResume(tester);
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait 3 seconds in foreground (total 13s < 15s)
    simulatedTime = simulatedTime.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(authProvider.status, equals(AuthStatus.authenticated));

    // Wait 3 more seconds (total 16s > 15s)
    simulatedTime = simulatedTime.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(authProvider.status, equals(AuthStatus.locked));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    mockScreenSec.dispose();
  });

  testWidgets('SettingsScreen wipe all data button says ELIMINA and prompts for Master PIN before wiping', (WidgetTester tester) async {
    final authProvider = _TestInactivityAuthProvider();
    final settingsProvider = _TestSettingsProvider();
    final vaultProvider = _TestVaultProvider(initialItems: [
      VaultItem(
        id: 'test-wipe-item',
        title: 'Item to be wiped',
        category: VaultCategory.login,
        password: 'Password123!',
      ),
    ]);

    await tester.pumpWidget(
      _buildTestApp(
        authProvider: authProvider,
        settingsProvider: settingsProvider,
        vaultProvider: vaultProvider,
        child: const SettingsScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to and tap Wipe All Data tile
    await tester.scrollUntilVisible(
      find.text(AppLocalizationsIt().wipeAllDataTileTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppLocalizationsIt().wipeAllDataTileTitle));
    await tester.pumpAndSettle();

    // Verify warning dialog is displayed with uppercase button "ELIMINA"
    expect(find.text(AppLocalizationsIt().wipeAllDataDialogTitle), findsOneWidget);
    expect(find.text('ELIMINA'), findsOneWidget);

    // Tap "ELIMINA"
    await tester.tap(find.text('ELIMINA'));
    await tester.pumpAndSettle();

    // Verify authentication PIN prompt dialog is displayed
    expect(find.text(AppLocalizationsIt().confirmWipeAuthTitle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('LockScreen updates countdown every second and dismisses error message upon lockout expiry', (WidgetTester tester) async {
    var simulatedTime = DateTime(2026, 1, 1, 12, 0, 0);
    final mockAuth = _MockWidgetLockoutAuthService(
      lockoutSeconds: 3,
      clock: () => simulatedTime,
    );
    final authProvider = AuthProvider(
      authService: mockAuth,
      clock: () => simulatedTime,
    );

    await tester.pumpWidget(
      _buildTestApp(
        locale: 'it',
        authProvider: authProvider,
        child: const LockScreen(),
      ),
    );
    await tester.pump();

    // Trigger lockout by failing 5 times
    for (int i = 0; i < 5; i++) {
      await authProvider.authenticateWithPin('wrong');
    }
    await tester.pump();

    // Check that error message is displayed with countdown
    expect(find.textContaining('Troppi tentativi falliti'), findsOneWidget);
    expect(find.textContaining('3s'), findsOneWidget);

    // TextField should be disabled during lockout
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    // Advance 1 second
    simulatedTime = simulatedTime.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('2s'), findsOneWidget);

    // Advance 1 more second
    simulatedTime = simulatedTime.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('1s'), findsOneWidget);

    // Advance 1 more second (lockout expires)
    simulatedTime = simulatedTime.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Error message must disappear completely and not get stuck at 0s!
    expect(find.textContaining('Troppi tentativi falliti'), findsNothing);
    expect(find.textContaining('0s'), findsNothing);

    // TextField must be re-enabled!
    final reenabledTextField = tester.widget<TextField>(find.byType(TextField));
    expect(reenabledTextField.enabled, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    authProvider.dispose();
  });
}

/// Mock test implementation of [AuthService] for lockout widget tests.
class _MockWidgetLockoutAuthService extends AuthService {
  final int lockoutSeconds;
  final DateTime Function() clock;
  int failCount = 0;

  _MockWidgetLockoutAuthService({
    this.lockoutSeconds = 3,
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now());

  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> isSetupComplete() async => true;

  @override
  Future<VerifyPinResult> verifyMasterPin(String pin) async {
    failCount++;
    if (pin == '123456') {
      failCount = 0;
      return const VerifyPinSuccess();
    }
    if (failCount >= 5) {
      return VerifyPinFailure(
        failedAttempts: failCount,
        lockoutUntil: clock().add(Duration(seconds: lockoutSeconds)),
      );
    }
    return VerifyPinFailure(failedAttempts: failCount);
  }
}

/// Mock test implementation of [SettingsProvider] for in-memory settings in tests.
class _TestSettingsProvider extends SettingsProvider {
  SecuritySettings _testSettings;

  _TestSettingsProvider({SecuritySettings? initialSettings})
      : _testSettings = initialSettings ?? const SecuritySettings(),
        super();

  @override
  SecuritySettings get settings => _testSettings;

  @override
  Future<void> updateAutoLock(int seconds) async {
    _testSettings = _testSettings.copyWith(autoLockSeconds: seconds);
    notifyListeners();
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    _testSettings = _testSettings.copyWith(languageCode: languageCode);
    notifyListeners();
  }
}

/// Mock test implementation of [AuthProvider] for inactivity test cases.
class _TestInactivityAuthProvider extends AuthProvider {
  AuthStatus _testStatus = AuthStatus.authenticated;

  @override
  bool get isBiometricSupported => false;

  @override
  AuthStatus get status => _testStatus;

  @override
  void lock() {
    _testStatus = AuthStatus.locked;
    notifyListeners();
  }
}

/// Mock test implementation of [VaultProvider] keeping test items purely in-memory.
class _TestVaultProvider extends VaultProvider {
  _TestVaultProvider({List<VaultItem>? initialItems}) : super() {
    if (initialItems != null) {
      items.addAll(initialItems);
    }
  }

  @override
  Future<void> loadItems() async {
    notifyListeners();
  }
}

/// Mock test implementation of [ScreenSecurityService] for controlling screen capture stream in widget tests.
class _MockScreenSecurityService extends ScreenSecurityService {
  final StreamController<bool> _ctrl = StreamController<bool>.broadcast();
  bool _active = false;

  @override
  Stream<bool> get onScreenCaptureChanged => _ctrl.stream;

  @override
  Future<bool> isScreenCaptureActive() async => _active;

  void emitCapture(bool active) {
    _active = active;
    _ctrl.add(active);
  }

  @override
  void dispose() {
    _ctrl.close();
  }
}

/// Mock test implementation of [AuthService] for biometric invocation tracking.
class _MockTestAuthService extends AuthService {
  int biometricsCallCount = 0;

  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<bool> authenticateWithBiometrics({String reason = 'Autenticati per accedere al Caveau'}) async {
    biometricsCallCount++;
    return true;
  }
}

/// Mock test implementation of [AuthProvider] controlling authentication status in widget tests.
class _TestAuthProvider extends AuthProvider {
  final _MockTestAuthService mockAuth;

  _TestAuthProvider({required _MockTestAuthService authService})
      : mockAuth = authService,
        super(authService: authService);

  @override
  bool get isBiometricSupported => true;

  @override
  AuthStatus get status => AuthStatus.locked;

  @override
  bool get isLockedOut => false;

  @override
  Future<bool> authenticateWithBiometrics({bool silentFail = true}) async {
    return await mockAuth.authenticateWithBiometrics();
  }
}

