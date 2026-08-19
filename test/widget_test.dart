import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caveau/main.dart';
import 'package:caveau/core/localization/app_localizations.dart';
import 'package:caveau/models/vault_item.dart';
import 'package:caveau/providers/vault_provider.dart';
import 'package:caveau/providers/settings_provider.dart';
import 'package:caveau/core/services/secure_storage_service.dart';
import 'package:caveau/core/services/auth_service.dart';
import 'package:caveau/providers/auth_provider.dart';
import 'package:caveau/views/auth/lock_screen.dart';
import 'package:caveau/views/auth/onboarding_screen.dart';
import 'package:caveau/views/vault/vault_detail_screen.dart';
import 'package:caveau/views/widgets/language_selector_button.dart';
import 'package:caveau/views/widgets/vault_card.dart';
import 'package:caveau/views/widgets/vault_logo.dart';
import 'package:caveau/views/widgets/privacy_shield.dart';
import 'package:caveau/views/security/security_audit_screen.dart';
import 'package:caveau/views/generator/password_generator_screen.dart';
import 'package:caveau/views/settings/settings_screen.dart';
import 'package:caveau/views/vault/vault_home_screen.dart';
import 'package:caveau/core/constants/app_colors.dart';

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
    child: MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

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
    expect(find.text('Italiano'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    // Tap Español
    await tester.tap(find.text('Español'));
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
}

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
