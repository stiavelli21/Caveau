import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caveau/main.dart';
import 'package:caveau/models/vault_item.dart';
import 'package:caveau/providers/vault_provider.dart';
import 'package:caveau/providers/settings_provider.dart';
import 'package:caveau/core/services/secure_storage_service.dart';
import 'package:caveau/views/vault/vault_detail_screen.dart';
import 'package:caveau/views/widgets/vault_card.dart';
import 'package:caveau/views/widgets/vault_logo.dart';

void main() {
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vaultProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(
          home: VaultDetailScreen(itemId: 'test_item_1'),
        ),
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vaultProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(
          home: VaultDetailScreen(itemId: 'test_note_1'),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Server Backup Codes'), findsOneWidget);
    expect(find.text('Contenuto Nota'), findsOneWidget);
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vaultProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VaultCard(
              item: item,
              onTap: () {},
              onToggleFavorite: () {},
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
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
    expect(find.text('Conferma'), findsNothing); // Button is 'Elimina'
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
}

