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
}