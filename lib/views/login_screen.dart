import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String userId, {bool isNewUser}) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginTab = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginTab) {
        final profile = await _authService.loginWithEmail(
          _emailController.text,
          _passwordController.text,
        );
        widget.onLoginSuccess(profile.id, isNewUser: false);
      } else {
        final profile = await _authService.registerWithEmail(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
        widget.onLoginSuccess(profile.id, isNewUser: !profile.hasSeenOnboarding);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtextColor = textColor.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Title
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 44,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PointSpend',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aktivite yap, puan kazan, ödüllerini aç!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLoginTab = true;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isLoginTab ? cardBg : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isLoginTab
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Text(
                                      'Giriş Yap',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isLoginTab ? const Color(0xFF16A34A) : subtextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLoginTab = false;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isLoginTab ? cardBg : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isLoginTab
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                          : null,
                                    ),
                                    child: Text(
                                      'Kayıt Ol',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: !_isLoginTab ? const Color(0xFF16A34A) : subtextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!_isLoginTab) ...[
                          TextFormField(
                            controller: _nameController,
                            maxLength: 40,
                            inputFormatters: [LengthLimitingTextInputFormatter(40)],
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              labelStyle: TextStyle(color: subtextColor),
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Adınızı giriniz';
                              if (val.trim().length < 2) return 'Ad soyad en az 2 karakter olmalıdır';
                              if (val.trim().length > 40) return 'Ad soyad en fazla 40 karakter olabilir';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        TextFormField(
                          controller: _emailController,
                          maxLength: 60,
                          inputFormatters: [LengthLimitingTextInputFormatter(60)],
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'E-Posta Adresi',
                            labelStyle: TextStyle(color: subtextColor),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (val) {
                            if (val == null || !val.contains('@')) return 'Geçerli e-posta giriniz';
                            if (val.trim().length > 60) return 'E-posta en fazla 60 karakter olabilir';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordController,
                          maxLength: 32,
                          inputFormatters: [LengthLimitingTextInputFormatter(32)],
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            labelStyle: TextStyle(color: subtextColor),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: subtextColor,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) return 'En az 6 karakter giriniz';
                            if (val.length > 32) return 'Şifre en fazla 32 karakter olabilir';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        if (!_isLoginTab) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            maxLength: 32,
                            inputFormatters: [LengthLimitingTextInputFormatter(32)],
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Şifre Tekrarı',
                              labelStyle: TextStyle(color: subtextColor),
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: subtextColor,
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            validator: (val) {
                              if (_isLoginTab) return null;
                              if (val == null || val.isEmpty) return 'Şifrenizi tekrar giriniz';
                              if (val != _passwordController.text) return 'Şifreler birbiriyle eşleşmiyor';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    _isLoginTab ? 'Giriş Yap' : 'Hesap Oluştur',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
