import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rooted_upright_mobile/services/auth_service.dart';
import 'widget_guide_screen.dart';
import 'catalog_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controls for capturing user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Tracks login request in progress
  bool _isLoading = false;

  // Tracks whether password is visible
  bool _obscurePassword = true;

  // Tracks remember me toggle
  bool _rememberMe = false;

  // Holds any error message to display
  String? _errorMessage;

  // Auth service instance
  final AuthService _authService = AuthService();

  // Handles login button tap
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (session != null && session.isValid()) {
        // Save credentials if remember me is checked
      if (_rememberMe) {
          await _authService.saveCredentials(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
        final userId = _authService.getUserSub(session);
        // Check widget is still mounted before navigating
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CatalogScreen(userId: userId ?? ''),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid credentials. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Loads saved credentials on screen init
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await _authService.getSavedCredentials();
    if (credentials != null && credentials['email'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Void background color
      backgroundColor: const Color(0xFF080d00),
      // SafeArea ensures content is not obscured by system UI
      body: SafeArea(
        // Stack allows for layering widgets on top of each other
        child: Stack(
          children: [
            // Main login content
            // SingleChildScrollView handles small screens and keyboard overflow
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header section
                    const SizedBox(height: 48),
                    Text(
                      '2026',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 4,
                        color: Color(0x99aaff00),
                        fontFamily: 'monospace',
                      ),
                    ),
                    // Beta badge
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0x55aaff00)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 3,
                          color: Color(0x77aaff00),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ROOTED\nUPRIGHT',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFaaff00),
                        letterSpacing: 2,
                      ),
                    ),
                    // SizedBox is Flutter's spacer, like margin in CSS
                    const SizedBox(height: 8),
                    Text(
                      'PLANT INTELLIGENCE SYSTEM',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        color: Color(0x77aaff00),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Divider
                    const Divider(color: Color(0x22aaff00)),
                    const SizedBox(height: 32),
                    // Input section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'USER ID',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 3,
                          color: Color(0x99aaff00),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      // Email input
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Color(0xFFaaff00),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'email address',
                        hintStyle: const TextStyle(
                          color: Color(0x55aaff00),
                          fontFamily: 'monospace',
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0d1500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0x33aaff00),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0x33aaff00),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFaaff00),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ACCESS CODE (PASSWORD)',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 3,
                          color: Color(0x99aaff00),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      // Password input
                      // obscureText hides the input, like type="password" in HTML
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      style: const TextStyle(
                        color: Color(0xFFaaff00),
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          // Toggle password visibility
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0x77aaff00),
                          ),
                        ),
                        hintText: '••••••••',
                        hintStyle: const TextStyle(
                          color: Color(0x55aaff00),
                          fontFamily: 'monospace',
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0d1500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0x33aaff00),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0x33aaff00),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFaaff00),
                          ),
                        ),
                      ),
                    ),
                    // Remember me toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          checkColor: const Color(0xFF080d00),
                          fillColor: WidgetStateProperty.all(const Color(0xFFaaff00)),
                        ),
                        const Text(
                          'REMEMBER ME',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 3,
                            color: Color(0x77aaff00),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'FORGOT?',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2,
                              color: Color(0x77aaff00),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Button section
                    SizedBox(
                      // double.infinity makes the button take the full width of its parent, like width: 100% in CSS
                      width: double.infinity,
                      child: ElevatedButton(
                        // Login button
                        // r is the callback for when the button is tapped - currently empty -- auth logic comes later.
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaaff00),
                          foregroundColor: const Color(0xFF080d00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'INITIALIZE',
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Error message display
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFffb000),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                    TextButton(
                      // Register link
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'NEW SPECIMEN? REGISTER',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0x55aaff00),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Easter egg icon
            Positioned(
              bottom: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WidgetGuideScreen(),
                    ),
                  );
                },
                child: const Text('🌿', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
