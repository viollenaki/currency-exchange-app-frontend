import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_background/animated_background.dart' as animated_bg; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'package:currency_exchange_app/providers/auth_provider.dart';
import 'package:currency_exchange_app/screens/home_screen.dart' as home_screen;

class CustomAnimatedBackground extends StatefulWidget {
  final Widget child;

  const CustomAnimatedBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<CustomAnimatedBackground> createState() => _CustomAnimatedBackgroundState();
}

class _CustomAnimatedBackgroundState extends State<CustomAnimatedBackground>
    with TickerProviderStateMixin { 
  // Interface Colors
  static const Color primaryRed = Color(0xFFCC353C); 
  static const Color primaryBlue = Color(0xFF0B3A96); 
  static const Color darkBlue = Color(0xFF030836); 
  static const Color blackColor = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return animated_bg.AnimatedBackground(
      behaviour: animated_bg.RandomParticleBehaviour(
        options: animated_bg.ParticleOptions(
          baseColor: Colors.white.withOpacity(0.5),
          spawnOpacity: 0.0,
          opacityChangeRate: 0.25,
          minOpacity: 0.1,
          maxOpacity: 0.4,
          spawnMinSpeed: 30.0,
          spawnMaxSpeed: 70.0,
          spawnMinRadius: 5.0,
          spawnMaxRadius: 15.0,
          particleCount: 50,
        ),
      ),
      vsync: this, 
      child: widget.child,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  bool _obscurePassword = true;

  late AnimationController _loginCardController;
  late Animation<double> _loginCardScaleAnimation;
  late Animation<double> _loginCardFadeAnimation;

  static const Color primaryRed = Color(0xFFCC353C); 
  static const Color primaryBlue = Color(0xFF0B3A96); 
  static const Color darkBlue = Color(0xFF030836);
  static const Color blackColor = Color(0xFF000000); 
  @override
  void initState() {
    super.initState();

    _loginCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loginCardScaleAnimation = CurvedAnimation(
      parent: _loginCardController,
      curve: Curves.elasticOut,
    );

    _loginCardFadeAnimation = CurvedAnimation(
      parent: _loginCardController,
      curve: Curves.easeIn,
    );

    _loginCardController.forward();
  }

  @override
  void dispose() {
    _loginCardController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final authProv = context.read<AuthProvider>();
      await authProv.login(_usernameCtrl.text, _passwordCtrl.text);
      if (authProv.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          _createFadeScaleTransition(const home_screen.OperationMainScreen()),
        );
      } else {
        setState(() {
          _errorMsg = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomAnimatedBackground(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = _getCardWidth(constraints.maxWidth);
              return ScaleTransition(
                scale: _loginCardScaleAnimation,
                child: FadeTransition(
                  opacity: _loginCardFadeAnimation,
                  child: Card(
                    color: Colors.white.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 12,
                    shadowColor: Colors.black54,
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.symmetric(
                          vertical: 40.0, horizontal: 32.0),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryBlue),
                              ),
                            )
                          : _buildFormFields(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _getCardWidth(double maxWidth) {
    if (maxWidth > 2000) {
      return 600;
    } else if (maxWidth > 1600) {
      return 500;
    } else if (maxWidth > 1200) {
      return 450;
    } else if (maxWidth > 800) {
      return 400;
    } else if (maxWidth > 600) {
      return 350;
    } else {
      return maxWidth * 0.9;
    }
  }

  Widget _buildFormFields(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _loginCardController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loginCardController.value * 2 * pi,
                child: child,
              );
            },
            child: Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CurrencyX Login',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 32),

          _buildAnimatedTextField(
            controller: _usernameCtrl,
            label: 'Username',
            icon: Icons.person,
            obscureText: false,
            validator: (val) =>
                val == null || val.isEmpty ? 'Please enter username' : null,
          ),
          const SizedBox(height: 24),

          _buildAnimatedTextField(
            controller: _passwordCtrl,
            label: 'Password',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            validator: (val) =>
                val == null || val.isEmpty ? 'Please enter password' : null,
          ),
          const SizedBox(height: 16),

          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontFamily: 'RobotoMono'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          home_screen.GlowingButton(
            text: 'Login',
            color: primaryBlue,
            onPressed: _isLoading ? null : _onLogin,
            isLoading: _isLoading,
            textColor: Colors.white,
            child: const Icon(Icons.login),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryBlue,
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'RobotoMono',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: primaryBlue,
            semanticLabel: '$label Icon',
          ),
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontFamily: 'RobotoMono',
          ),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryBlue,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          suffixIcon: label.toLowerCase() == 'password'
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: primaryBlue,
                    semanticLabel:
                        _obscurePassword ? 'Show Password' : 'Hide Password',
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Route _createFadeScaleTransition(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = Curves.easeInOut;
        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        final fadeTransition = FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

        final scaleTransition = ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
          child: fadeTransition,
        );

        return scaleTransition;
      },
    );
  }
}
