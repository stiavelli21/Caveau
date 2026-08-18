import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../generator/password_generator_screen.dart';
import '../widgets/password_strength_bar.dart';

class VaultEditorScreen extends StatefulWidget {
  final VaultItem? initialItem;
  final VaultCategory? preselectedCategory;

  const VaultEditorScreen({
    super.key,
    this.initialItem,
    this.preselectedCategory,
  });

  @override
  State<VaultEditorScreen> createState() => _VaultEditorScreenState();
}

class _VaultEditorScreenState extends State<VaultEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late VaultCategory _category;
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _websiteController;
  late TextEditingController _notesController;

  // Card fields
  late TextEditingController _cardHolderController;
  late TextEditingController _cardNumberController;
  late TextEditingController _cardExpiryController;
  late TextEditingController _cardCvvController;
  late TextEditingController _cardPinController;

  // Identity / API
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _idNumberController;
  late TextEditingController _apiKeySecretController;

  bool _obscurePassword = true;
  bool _obscureCvv = true;
  bool _obscureCardPin = true;
  bool _obscureApiSecret = true;
  bool _isFavorite = false;

  final List<CustomField> _customFields = [];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _category = item?.category ?? widget.preselectedCategory ?? VaultCategory.login;
    _isFavorite = item?.isFavorite ?? false;

    _titleController = TextEditingController(text: item?.title ?? '');
    _usernameController = TextEditingController(text: item?.username ?? '');
    _passwordController = TextEditingController(text: item?.password ?? '');
    _websiteController = TextEditingController(text: item?.websiteUrl ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _cardHolderController = TextEditingController(text: item?.cardHolder ?? '');
    _cardNumberController = TextEditingController(text: item?.cardNumber ?? '');
    _cardExpiryController = TextEditingController(text: item?.cardExpiry ?? '');
    _cardCvvController = TextEditingController(text: item?.cardCvv ?? '');
    _cardPinController = TextEditingController(text: item?.cardPin ?? '');

    _emailController = TextEditingController(text: item?.email ?? '');
    _phoneController = TextEditingController(text: item?.phone ?? '');
    _idNumberController = TextEditingController(text: item?.idNumber ?? '');
    _apiKeySecretController = TextEditingController(text: item?.apiKeySecret ?? '');

    if (item != null) {
      _customFields.addAll(item.customFields);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardPinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _apiKeySecretController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vaultProvider = context.read<VaultProvider>();

    final item = VaultItem(
      id: widget.initialItem?.id,
      title: _titleController.text.trim(),
      category: _category,
      isFavorite: _isFavorite,
      createdAt: widget.initialItem?.createdAt,
      username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
      websiteUrl: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      cardHolder: _cardHolderController.text.trim().isEmpty ? null : _cardHolderController.text.trim(),
      cardNumber: _cardNumberController.text.trim().isEmpty ? null : _cardNumberController.text.trim(),
      cardExpiry: _cardExpiryController.text.trim().isEmpty ? null : _cardExpiryController.text.trim(),
      cardCvv: _cardCvvController.text.trim().isEmpty ? null : _cardCvvController.text.trim(),
      cardPin: _cardPinController.text.trim().isEmpty ? null : _cardPinController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
      apiKeySecret: _apiKeySecretController.text.trim().isEmpty ? null : _apiKeySecretController.text.trim(),
      customFields: _customFields,
    );

    if (widget.initialItem == null) {
      await vaultProvider.addItem(item);
    } else {
      await vaultProvider.updateItem(item);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openGenerator() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => PasswordGeneratorScreen(
          onPasswordSelected: (pwd) {
            setState(() {
              _passwordController.text = pwd;
            });
          },
        ),
      ),
    );
  }

  void _addCustomField() {
    showDialog(
      context: context,
      builder: (ctx) {
        final labelCtrl = TextEditingController();
        final valueCtrl = TextEditingController();
        bool isSecret = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight, size: 22),
                  SizedBox(width: 10),
                  Text('Campo Personalizzato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Etichetta (es. Domanda segreta)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(labelText: 'Valore'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isSecret,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setDialogState(() => isSecret = v ?? false),
                      ),
                      const Expanded(
                        child: Text('Nascondi valore (Dato segreto)', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (labelCtrl.text.trim().isNotEmpty && valueCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _customFields.add(
                                CustomField(
                                  label: labelCtrl.text.trim(),
                                  value: valueCtrl.text.trim(),
                                  isSecret: isSecret,
                                ),
                              );
                            });
                            Navigator.of(ctx).pop();
                          }
                        },
                        child: const Text('Aggiungi'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Elemento' : 'Nuovo Elemento'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? AppColors.warning : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.success),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Segmented Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: VaultCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.displayName),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.25),
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Title Field
              TextFormField(
                controller: _titleController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Inserisci un titolo' : null,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  hintText: 'Es. Google, Netflix, Carta Principale',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Category Specific Fields
              if (_category == VaultCategory.login) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Utente / Email',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_fix_high_rounded,
                              color: AppColors.primaryLight),
                          tooltip: 'Genera password',
                          onPressed: _openGenerator,
                        ),
                      ],
                    ),
                  ),
                ),
                PasswordStrengthBar(password: _passwordController.text),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Sito Web / URL',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
              ] else if (_category == VaultCategory.card) ...[
                TextFormField(
                  controller: _cardHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Intestatario Carta',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Numero Carta',
                    hintText: '1234 5678 9012 3456',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cardExpiryController,
                        decoration: const InputDecoration(
                          labelText: 'Scadenza',
                          hintText: 'MM/AA',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cardCvvController,
                        obscureText: _obscureCvv,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CVV / CVC',
                          prefixIcon: const Icon(Icons.security_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCvv
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscureCvv = !_obscureCvv),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardPinController,
                  obscureText: _obscureCardPin,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'PIN della Carta',
                    prefixIcon: const Icon(Icons.pin_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCardPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCardPin = !_obscureCardPin),
                    ),
                  ),
                ),
              ] else if (_category == VaultCategory.identity) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Codice Fiscale / Numero Documento',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ] else if (_category == VaultCategory.note) ...[
                TextFormField(
                  controller: _notesController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Contenuto della Nota',
                    hintText: 'Scrivi qui le tue note crittografate, chiavi di ripristino o testi riservati...',
                    alignLabelWithHint: true,
                  ),
                ),
              ] else if (_category == VaultCategory.apiKey) ...[
                TextFormField(
                  controller: _apiKeySecretController,
                  obscureText: _obscureApiSecret,
                  decoration: InputDecoration(
                    labelText: 'API Secret / Token',
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureApiSecret
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureApiSecret = !_obscureApiSecret),
                    ),
                  ),
                ),
              ],

              if (_category != VaultCategory.note) ...[
                const SizedBox(height: 16),
                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note Aggiuntive (opzionale)',
                    hintText: 'Note o promemoria...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],

              // Custom Fields List
              if (_customFields.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Campi Personalizzati',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._customFields.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final field = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.label,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                field.isSecret ? '••••••••' : field.value,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.dangerLight, size: 20),
                          onPressed: () {
                            setState(() => _customFields.removeAt(idx));
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aggiungi Campo Personalizzato'),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Salva Modifiche' : 'Salva nel Caveau'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
