import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── Animation Controllers ──────────────────────────────
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _cardController;
  late AnimationController _scanlineController;
  late AnimationController _pulseController;

  // ── Background
  late Animation<double> _bgFadeAnim;

  // ── Logo
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoFadeAnim;
  late Animation<Offset> _logoSlideAnim;

  // ── Card
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  // ── Scanline sweep (techy effect)
  late Animation<double> _scanlineAnim;

  // ── Pulse ring on logo
  late Animation<double> _pulseAnim;

  // ── Staggered field animations
  late Animation<double> _emailFadeAnim;
  late Animation<double> _passwordFadeAnim;
  late Animation<double> _buttonFadeAnim;
  late Animation<Offset> _emailSlideAnim;
  late Animation<Offset> _passwordSlideAnim;
  late Animation<Offset> _buttonSlideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFadeAnim = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeIn,
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _logoScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _logoSlideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)),
    );

    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scanlineAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _scanlineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _cardFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _cardSlideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _emailFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.25, 0.65, curve: Curves.easeOut)),
    );
    _emailSlideAnim = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.25, 0.65, curve: Curves.easeOut)),
    );

    _passwordFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.45, 0.78, curve: Curves.easeOut)),
    );
    _passwordSlideAnim = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.45, 0.78, curve: Curves.easeOut)),
    );

    _buttonFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );
    _buttonSlideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack)),
    );
  }

  Future<void> _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _scanlineController.forward();
    _pulseController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardController.forward();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(_emailController.text, _passwordController.text);

    if (authProvider.isLoggedIn && mounted) {
      switch (authProvider.user!.role) {
        case 'petugas':
          Navigator.pushReplacementNamed(context, AppRoutes.petugasHome);
          break;
        case 'supervisor':
          Navigator.pushReplacementNamed(context, AppRoutes.supervisorHome);
          break;
        case 'warga':
          Navigator.pushReplacementNamed(context, AppRoutes.wargaHome);
          break;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    _cardController.dispose();
    _scanlineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041221),
      body: FadeTransition(
        opacity: _bgFadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Padding vertikal disesuaikan agar konten tetap terasa center
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo ───────────────────────────────
                      _buildAnimatedLogo(),

                      // Jarak logo ke card dikurangi proporsional
                      const SizedBox(height: 28),

                      // ── Form Card ───────────────────────────
                      SlideTransition(
                        position: _cardSlideAnim,
                        child: FadeTransition(
                          opacity: _cardFadeAnim,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FB),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF4A90D9).withOpacity(0.08),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ── Email Field ─────────────────
                                SlideTransition(
                                  position: _emailSlideAnim,
                                  child: FadeTransition(
                                    opacity: _emailFadeAnim,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('EMAIL PENGGUNA'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                          controller: _emailController,
                                          icon: Icons.badge_outlined,
                                          hintText: 'Masukkan email Anda',
                                          keyboardType: TextInputType.emailAddress,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ── Password Field ──────────────
                                SlideTransition(
                                  position: _passwordSlideAnim,
                                  child: FadeTransition(
                                    opacity: _passwordFadeAnim,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('KATA SANDI'),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                          controller: _passwordController,
                                          icon: Icons.lock_outline,
                                          hintText: '• • • • • • • • •',
                                          obscureText: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // ── Tombol & Footer ─────────────
                                SlideTransition(
                                  position: _buttonSlideAnim,
                                  child: FadeTransition(
                                    opacity: _buttonFadeAnim,
                                    child: Column(
                                      children: [
                                        if (auth.errorMessage != null)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.red.shade200),
                                            ),
                                            child: Text(
                                              auth.errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed: auth.isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0F2A44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 4,
                                            ),
                                            child: auth.isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'MASUK',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 4,
                                                          color: Color(0xFFD1E4FF),
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Icon(
                                                        Icons.login,
                                                        color: Color(0xFFD1E4FF),
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const ForgotPasswordScreen(),
                                                ),
                                              ),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text(
                                                'LUPA SANDI?',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F2A44),
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F2A44).withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {},
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text(
                                                'BANTUAN',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F2A44),
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
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

                      const SizedBox(height: 24),

                      // ── Versi ───────────────────────────────
                      FadeTransition(
                        opacity: _buttonFadeAnim,
                        child: const Text(
                          'V4.2.0-SECURE',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 9,
                            letterSpacing: 3,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Animated Logo Widget ─────────────────────────────────
  Widget _buildAnimatedLogo() {
    return SlideTransition(
      position: _logoSlideAnim,
      child: FadeTransition(
        opacity: _logoFadeAnim,
        child: ScaleTransition(
          scale: _logoScaleAnim,
          child: SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Pulse ring (ukuran disesuaikan dengan logo baru)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: (1.0 - _pulseAnim.value).clamp(0.0, 1.0),
                      child: Container(
                        width: 140 + (70 * _pulseAnim.value),
                        height: 140 + (70 * _pulseAnim.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4A90D9).withOpacity(
                              (0.5 * (1 - _pulseAnim.value)).clamp(0.0, 1.0),
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── Logo dengan scanline overlay
                ClipRect(
                  child: Stack(
                    children: [
                      Image.network(
                        'https://dwyfjwwgrtdspgdaifyv.supabase.co/storage/v1/object/public/logo/logo_aegis_full.png',
                        height: 190,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 190,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white.withOpacity(0.5),
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield, size: 72,
                                  color: Colors.white.withOpacity(0.8)),
                              const SizedBox(height: 8),
                              const Text(
                                'AEGIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // ── Scanline sweep
                      AnimatedBuilder(
                        animation: _scanlineAnim,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final sweepY = _scanlineAnim.value * constraints.maxHeight;
                                return CustomPaint(
                                  painter: _ScanlinePainter(sweepY: sweepY),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F2A44),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0F2A44),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF0F2A44).withOpacity(0.45),
            size: 20,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFF0F2A44).withOpacity(0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter untuk efek scanline ──────────────────────
class _ScanlinePainter extends CustomPainter {
  final double sweepY;

  _ScanlinePainter({required this.sweepY});

  @override
  void paint(Canvas canvas, Size size) {
    if (sweepY < 0 || sweepY > size.height + 40) return;

    final linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF7EC8F4).withOpacity(0.0),
          const Color(0xFF7EC8F4).withOpacity(0.7),
          const Color(0xFFD1E4FF).withOpacity(0.95),
          const Color(0xFF7EC8F4).withOpacity(0.7),
          const Color(0xFF7EC8F4).withOpacity(0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0],
      ).createShader(Rect.fromLTWH(0, sweepY - 1, size.width, 2));

    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 1, size.width, 2),
      linePaint,
    );

    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7EC8F4).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, sweepY, size.width, 30));

    canvas.drawRect(
      Rect.fromLTWH(0, sweepY, size.width, 30),
      glowPaint,
    );

    final glowAbovePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF7EC8F4).withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, sweepY - 20, size.width, 20));

    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 20, size.width, 20),
      glowAbovePaint,
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) =>
      oldDelegate.sweepY != sweepY;
}