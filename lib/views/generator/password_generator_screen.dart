import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/utils/password_generator.dart';
import '../widgets/password_strength_bar.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  final ValueChanged<String>? onPasswordSelected;

  const PasswordGeneratorScreen({
    super.key,
    this.onPasswordSelected,
  });

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeAmbiguous = false;

  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    final pwd = PasswordGenerator.generate(
      length: _length,
      includeUppercase: _includeUppercase,
      includeLowercase: _includeLowercase,
      includeNumbers: _includeNumbers,
      includeSymbols: _includeSymbols,
      excludeAmbiguous: _excludeAmbiguous,
    );
    setState(() {
      _generatedPassword = pwd;
    });
  }

  void _copy() {
    ClipboardService.copyWithAutoClear(_generatedPassword, autoClearSeconds: 30);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            SizedBox(width: 10),
            Text(
              'Password copiata (auto-clear 30s)',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generatore Password'),
      ),
      body: SafeArea(
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
              // Password Display Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _generatedPassword,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.primaryLight, size: 26),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _regenerate();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.textSecondary, size: 24),
                        onPressed: _copy,
                      ),
                    ],
                  ),
                  PasswordStrengthBar(password: _generatedPassword),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Length Slider Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lunghezza Caratteri',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Text(
                          '$_length',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceHighlight,
                    ),
                    child: Slider(
                      value: _length.toDouble(),
                      min: 8,
                      max: 48,
                      divisions: 40,
                      onChanged: (val) {
                        setState(() => _length = val.round());
                        _regenerate();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Character Sets Toggles
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Lettere Maiuscole (A-Z)',
                    value: _includeUppercase,
                    onChanged: (val) {
                      setState(() => _includeUppercase = val);
                      _regenerate();
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _buildToggleTile(
                    title: 'Lettere Minuscole (a-z)',
                    value: _includeLowercase,
                    onChanged: (val) {
                      setState(() => _includeLowercase = val);
                      _regenerate();
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _buildToggleTile(
                    title: 'Numeri (0-9)',
                    value: _includeNumbers,
                    onChanged: (val) {
                      setState(() => _includeNumbers = val);
                      _regenerate();
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _buildToggleTile(
                    title: 'Simboli Speciali (!@#\$%^&*)',
                    value: _includeSymbols,
                    onChanged: (val) {
                      setState(() => _includeSymbols = val);
                      _regenerate();
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _buildToggleTile(
                    title: 'Escludi caratteri ambigui (Il1O0)',
                    value: _excludeAmbiguous,
                    onChanged: (val) {
                      setState(() => _excludeAmbiguous = val);
                      _regenerate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.onPasswordSelected != null)
              ElevatedButton.icon(
                onPressed: () {
                  widget.onPasswordSelected!(_generatedPassword);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Usa questa Password'),
              )
            else
              ElevatedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copia Password Negli Appunti'),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
