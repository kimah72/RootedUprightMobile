import 'package:amazon_cognito_identity_dart_2/cognito.dart';

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
}