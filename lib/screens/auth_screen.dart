import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flashdeck_mascot.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.authService,
    this.onRegistrationStarted,
    this.onRegistrationFinished,
    this.callbackError,
    super.key,
  });

  final AuthService authService;
  final VoidCallback? onRegistrationStarted;
  final VoidCallback? onRegistrationFinished;
  final String? callbackError;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _infoMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    var registrationStarted = false;
    try {
      final email = _emailController.text.trim();
      if (_isSignUp) {
        widget.onRegistrationStarted?.call();
        registrationStarted = true;
        final hasSession = await widget.authService.signUp(
          email: email,
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (!hasSession) {
          setState(() {
            _errorMessage =
                'สมัครไม่สำเร็จเพราะไม่มี session โปรดตรวจสอบการตั้งค่า '
                'Confirm email ใน Supabase Dashboard แล้วลองใหม่';
          });
        } else {
          await widget.authService.signOut();
          if (!mounted) return;
          setState(() {
            _isSignUp = false;
            _confirmPasswordController.clear();
            _errorMessage = null;
            _infoMessage = 'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ';
          });
        }
      } else {
        await widget.authService.signInWithPassword(
          email: email,
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyAuthError(error));
    } on Exception {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'เชื่อมต่อบริการไม่ได้ โปรดตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง';
      });
    } finally {
      if (registrationStarted) {
        widget.onRegistrationFinished?.call();
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (_isSignUp &&
        (error.code == 'user_already_exists' ||
            message.contains('already registered') ||
            message.contains('already exists'))) {
      return 'อีเมลนี้มีบัญชีอยู่แล้ว โปรดเข้าสู่ระบบหรือใช้อีเมลอื่น';
    }
    if (error.code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'อีเมลนี้ยังไม่ได้รับการยืนยัน โปรดเปิดอีเมลยืนยันก่อนเข้าสู่ระบบ';
    }
    if (error.statusCode == '429') {
      return 'ลองทำรายการบ่อยเกินไป โปรดรอสักครู่แล้วลองใหม่';
    }
    if (error is AuthWeakPasswordException || error.code == 'weak_password') {
      return 'รหัสผ่านยังไม่ปลอดภัยพอ โปรดตั้งรหัสผ่านที่คาดเดายากขึ้น';
    }
    if (message.contains('invalid login credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    return _isSignUp
        ? 'สมัครบัญชีไม่สำเร็จ โปรดตรวจสอบอีเมลและลองอีกครั้ง'
        : 'เข้าสู่ระบบไม่สำเร็จ โปรดตรวจสอบข้อมูลแล้วลองอีกครั้ง';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'กรุณากรอกอีเมล';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _isSignUp;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppTheme.space20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Center(child: FlashDeckMascot(size: 84)),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          isSignUp ? 'สร้างบัญชี FlashDeck' : 'ยินดีต้อนรับ',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          isSignUp
                              ? 'สมัครด้วยอีเมลและรหัสผ่าน'
                              : 'เข้าสู่ระบบเพื่อเริ่มใช้งาน FlashDeck',
                          textAlign: TextAlign.center,
                        ),
                        if (widget.callbackError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.callbackError!,
                            key: const ValueKey('auth-callback-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.space24),
                        TextFormField(
                          key: const ValueKey('auth-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'อีเมล',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        TextFormField(
                          key: const ValueKey('auth-password'),
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: isSignUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'รหัสผ่าน',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: _validatePassword,
                        ),
                        if (isSignUp) ...[
                          const SizedBox(height: AppTheme.space16),
                          TextFormField(
                            key: const ValueKey('auth-confirm-password'),
                            controller: _confirmPasswordController,
                            obscureText: true,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                              labelText: 'ยืนยันรหัสผ่าน',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณายืนยันรหัสผ่าน';
                              }
                              if (value != _passwordController.text) {
                                return 'รหัสผ่านไม่ตรงกัน';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            key: const ValueKey('auth-error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (_infoMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _infoMessage!,
                            key: const ValueKey('auth-info'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.space16),
                        FilledButton(
                          key: const ValueKey('auth-submit'),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'),
                        ),
                        TextButton(
                          onPressed: _isSubmitting ? null : _switchMode,
                          child: Text(
                            isSignUp
                                ? 'มีบัญชีแล้ว? เข้าสู่ระบบ'
                                : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
