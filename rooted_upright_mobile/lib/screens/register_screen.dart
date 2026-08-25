import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rooted_upright_mobile/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  String? _errorMessage;
  // Cognito requires a mailed verification code before an account can sign in
  bool _awaitingConfirmation = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'EMAIL and ACCESS CODE are required.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUp(email, password);
      if (!mounted) return;
      setState(() => _awaitingConfirmation = true);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter the verification code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.confirmSignUp(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account verified — sign in below.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await _authService.resendConfirmationCode(_emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    }
  }

  // Cognito exceptions carry a verbose `message`; keep the UI readable
  String _friendlyError(Object e) {
    final text = e.toString();
    final match = RegExp(r'message:\s*(.+)').firstMatch(text);
    return match?.group(1) ?? 'Something went wrong. Please try again.';
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0x55aaff00),
        fontFamily: 'monospace',
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0d1500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0x33aaff00)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0x33aaff00)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFaaff00)),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 3,
          color: Color(0x99aaff00),
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080d00),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080d00),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFaaff00)),
        title: Text(
          _awaitingConfirmation ? 'VERIFY ACCOUNT' : 'NEW SPECIMEN',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            color: const Color(0xFFaaff00),
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _awaitingConfirmation
                ? _buildConfirmationForm()
                : _buildRegisterForm(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRegisterForm() {
    return [
      _label('USER ID'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('email address'),
      ),
      const SizedBox(height: 20),
      _label('ACCESS CODE (PASSWORD)'),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: true,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('••••••••'),
      ),
      const SizedBox(height: 20),
      _label('CONFIRM ACCESS CODE'),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmPasswordController,
        obscureText: true,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('••••••••'),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFaaff00),
            foregroundColor: const Color(0xFF080d00),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            _isSubmitting ? 'REGISTERING...' : 'REGISTER',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: const TextStyle(
            color: Color(0xFFffb000),
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildConfirmationForm() {
    return [
      Text(
        'A verification code was sent to ${_emailController.text.trim()}.',
        style: const TextStyle(
          color: Color(0x99aaff00),
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      _label('VERIFICATION CODE'),
      const SizedBox(height: 8),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('000000'),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _confirmCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFaaff00),
            foregroundColor: const Color(0xFF080d00),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            _isSubmitting ? 'VERIFYING...' : 'CONFIRM',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: _resendCode,
        child: const Text(
          'RESEND CODE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: Color(0x77aaff00),
            fontFamily: 'monospace',
          ),
        ),
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 8),
        Text(
          _errorMessage!,
          style: const TextStyle(
            color: Color(0xFFffb000),
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ],
    ];
  }
}
