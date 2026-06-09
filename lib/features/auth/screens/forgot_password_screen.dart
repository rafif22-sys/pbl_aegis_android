// lib/features/auth/screens/forgot_password_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/forgot_password_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────
  int _step = 0; // 0: email, 1: otp, 2: new password, 3: sukses

  final _emailCtrl    = TextEditingController();
  final _otpCtrls     = List.generate(6, (_) => TextEditingController());
  final _otpFocuses   = List.generate(6, (_) => FocusNode());
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _isLoading     = false;
  bool _obscurePass   = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _resetToken;
  String  _email      = '';

  // ── Countdown resend OTP ───────────────────────────────
  int  _resendSeconds = 0;
  Timer? _resendTimer;

  // ── Animasi step transition ────────────────────────────
  late AnimationController _stepAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim  = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _stepAnim, curve: Curves.easeOutCubic));
    _stepAnim.forward();
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    _emailCtrl.dispose();
    for (final c in _otpCtrls)   c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Helper animasi pindah step ─────────────────────────
  Future<void> _goToStep(int step) async {
    await _stepAnim.reverse();
    setState(() {
      _step = step;
      _errorMessage = null;
    });
    _stepAnim.forward();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  // ── STEP 0: Kirim OTP ──────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ForgotPasswordService.sendOtp(email);
      _email = email;
      _startResendTimer();
      await _goToStep(1);
    } catch (_) {
      setState(() => _errorMessage = 'Tidak dapat terhubung ke server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── STEP 1: Verifikasi OTP ─────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode OTP.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ForgotPasswordService.verifyOtp(_email, otp);

      if (res['reset_token'] != null) {
        _resetToken = res['reset_token'] as String;
        await _goToStep(2);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'OTP tidak valid.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Tidak dapat terhubung ke server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── STEP 2: Reset password ─────────────────────────────
  Future<void> _resetPassword() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ForgotPasswordService.resetPassword(
        resetToken:           _resetToken!,
        password:             pass,
        passwordConfirmation: confirm,
      );

      if (res['message']?.toString().contains('berhasil') == true) {
        await _goToStep(3);
      } else {
        setState(() => _errorMessage = res['message'] ?? 'Gagal reset password.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Tidak dapat terhubung ke server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041221),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 20),
                onPressed: () {
                  if (_step == 0) {
                    Navigator.pop(context);
                  } else {
                    _goToStep(_step - 1);
                  }
                },
              )
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildEmailStep();
      case 1: return _buildOtpStep();
      case 2: return _buildNewPasswordStep();
      case 3: return _buildSuccessStep();
      default: return _buildEmailStep();
    }
  }

  // ── Step 0: Input Email ────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepIndicator(0),
        const SizedBox(height: 32),
        const Text('Lupa Password?',
            style: TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'Masukkan email akun AEGIS Anda.\nKami akan mengirimkan kode OTP.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        _buildLabel('ALAMAT EMAIL'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailCtrl,
          icon: Icons.email_outlined,
          hint: 'contoh@email.com',
          inputType: TextInputType.emailAddress,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildError(_errorMessage!),
        ],
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'KIRIM KODE OTP',
          icon: Icons.send_outlined,
          onPressed: _isLoading ? null : _sendOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Step 1: Input OTP ──────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepIndicator(1),
        const SizedBox(height: 32),
        const Text('Cek Email Anda',
            style: TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white54, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Kode OTP telah dikirim ke\n'),
              TextSpan(
                text: _email,
                style: const TextStyle(
                    color: Color(0xFF7EC8F4), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        _buildLabel('KODE OTP (6 DIGIT)'),
        const SizedBox(height: 12),
        _buildOtpBoxes(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildError(_errorMessage!),
        ],
        const SizedBox(height: 16),
        // Resend
        Row(
          children: [
            const Text('Tidak menerima kode? ',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            _resendSeconds > 0
                ? Text(
                    'Kirim ulang (${_resendSeconds}s)',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 13),
                  )
                : GestureDetector(
                    onTap: _isLoading ? null : () {
                      for (final c in _otpCtrls) c.clear();
                      _sendOtp();
                    },
                    child: const Text('Kirim ulang',
                        style: TextStyle(
                            color: Color(0xFF7EC8F4),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
          ],
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'VERIFIKASI OTP',
          icon: Icons.verified_outlined,
          onPressed: _isLoading ? null : _verifyOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Step 2: Password Baru ──────────────────────────────
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepIndicator(2),
        const SizedBox(height: 32),
        const Text('Password Baru',
            style: TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'Buat password baru yang kuat\ndan mudah diingat.',
          style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 36),
        _buildLabel('PASSWORD BARU'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passCtrl,
          icon: Icons.lock_outline,
          hint: 'Minimal 8 karakter',
          obscure: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF0F2A44).withOpacity(0.45),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 20),
        _buildLabel('KONFIRMASI PASSWORD'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _confirmCtrl,
          icon: Icons.lock_outline,
          hint: 'Ulangi password baru',
          obscure: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF0F2A44).withOpacity(0.45),
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildError(_errorMessage!),
        ],
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'SIMPAN PASSWORD',
          icon: Icons.save_outlined,
          onPressed: _isLoading ? null : _resetPassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // ── Step 3: Sukses ─────────────────────────────────────
  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F2A44),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.3),
                  blurRadius: 32, spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Color(0xFF7EC8F4), size: 52),
          ),
          const SizedBox(height: 28),
          const Text('Password Berhasil\nDiperbarui!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 14),
          const Text(
            'Silakan masuk menggunakan\npassword baru Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton(
            label: 'KEMBALI KE LOGIN',
            icon: Icons.login,
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  WIDGETS HELPERS
  // ══════════════════════════════════════════════════════

  Widget _buildStepIndicator(int current) {
    return Row(
      children: List.generate(3, (i) {
        final active = i == current;
        final done   = i < current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: done || active
                    ? const Color(0xFF4A90D9)
                    : Colors.white12,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: TextField(
            controller: _otpCtrls[i],
            focusNode: _otpFocuses[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Color(0xFF0F2A44)),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF4A90D9), width: 2),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && i < 5) {
                _otpFocuses[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _otpFocuses[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold,
          color: Colors.white54, letterSpacing: 2,
        ),
      );

  Widget _buildError(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    TextInputType inputType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F2A44)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon,
              color: const Color(0xFF0F2A44).withOpacity(0.45), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(
              color: const Color(0xFF0F2A44).withOpacity(0.3), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F2A44),
          disabledBackgroundColor: const Color(0xFF0F2A44).withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          letterSpacing: 3, color: Color(0xFFD1E4FF))),
                  const SizedBox(width: 10),
                  Icon(icon, color: const Color(0xFFD1E4FF), size: 18),
                ],
              ),
      ),
    );
  }
}