import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final userPool = CognitoUserPool(
    'us-east-1_yHc7CMv1O',
    '3isil38pk3rjglpvp0vse9q764',
  );

  // Authenticates user against Cognito user pool
  Future<CognitoUserSession?> signIn(String email, String password) async {
    final cognitoUser = CognitoUser(email, userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    try {
      return await cognitoUser.authenticateUser(authDetails);
    } catch (e) {
      // Surface the error to the caller
      rethrow;
    }
  }

  // Registers a new account in the Cognito user pool — email doubles as
  // the username, matching how sign-in already works
  Future<CognitoUserPoolData> signUp(String email, String password) async {
    return await userPool.signUp(
      email,
      password,
      userAttributes: [AttributeArg(name: 'email', value: email)],
    );
  }

  // Confirms a new account with the verification code Cognito emails out
  Future<bool> confirmSignUp(String email, String code) async {
    final cognitoUser = CognitoUser(email, userPool);
    return await cognitoUser.confirmRegistration(code);
  }

  // Resends the verification code if the original email didn't arrive
  Future<void> resendConfirmationCode(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    await cognitoUser.resendConfirmationCode();
  }

  // Kicks off the forgot-password flow -- Cognito emails a verification code
  Future<void> forgotPassword(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    await cognitoUser.forgotPassword();
  }

  // Completes the forgot-password flow with the emailed code and new password
  Future<bool> confirmForgotPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final cognitoUser = CognitoUser(email, userPool);
    return await cognitoUser.confirmPassword(code, newPassword);
  }

  // Extracts the user's unique sub from the identity token
  String? getUserSub(CognitoUserSession session) {
    final idToken = session.idToken.payload;
    return idToken['sub'] as String?;
  }

  // Saves credentials locally for remember me
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  // Retrieves saved credentials if they exist
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email') ?? '',
      'password': prefs.getString('password') ?? '',
    };
  }

  // Clears remembered credentials so the next login starts blank —
  // needed for logout, otherwise the old account keeps auto-filling
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
