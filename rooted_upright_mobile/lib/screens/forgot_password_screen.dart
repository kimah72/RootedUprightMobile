import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rooted_upright_mobile/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isSubmitting = false;
  String? _errorMessage;
  // Cognito requires a mailed code before a new password can be set
  bool _codeSent = false;

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your USER ID (email) first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.forgotPassword(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter the verification code.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.confirmForgotPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPasswordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset — sign in below.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Cognito exceptions carry a verbose `message`; keep the UI readable
  String _friendlyError(Object e) {
    final text = e.toString();
    final match = RegExp(r'message:\s*(.+)').firstMatch(text);
    return match?.group(1) ?? 'Something went wrong. Please try again.';
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0x55aaff00),
        fontFamily: 'monospace',
      ),
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
          'RESET ACCESS CODE',
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
            children: _codeSent ? _buildResetForm() : _buildRequestForm(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequestForm() {
    return [
      const Text(
        'Enter your account email and we\'ll send a verification code to reset your access code.',
        style: TextStyle(
          color: Color(0x99aaff00),
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      _label('USER ID'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('email address'),
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _requestCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFaaff00),
            foregroundColor: const Color(0xFF080d00),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            _isSubmitting ? 'SENDING...' : 'SEND CODE',
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

  List<Widget> _buildResetForm() {
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
      const SizedBox(height: 20),
      _label('NEW ACCESS CODE'),
      const SizedBox(height: 8),
      TextField(
        controller: _newPasswordController,
        obscureText: true,
        style: const TextStyle(color: Color(0xFFaaff00), fontFamily: 'monospace'),
        decoration: _fieldDecoration('••••••••'),
      ),
      const SizedBox(height: 20),
      _label('CONFIRM NEW ACCESS CODE'),
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
          onPressed: _isSubmitting ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFaaff00),
            foregroundColor: const Color(0xFF080d00),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text(
            _isSubmitting ? 'RESETTING...' : 'RESET PASSWORD',
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
        onPressed: _isSubmitting ? null : _requestCode,
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
