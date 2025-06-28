// lib/services/google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '555273000599-ocp59t7edk6vcagrfpjlpjkkm8vq46t9.apps.googleusercontent.com' : null,
    scopes: ['email', 'profile'],
    // DO NOT use serverClientId on web - it's not supported
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('DEBUG: Starting Google sign-in...');
      
      GoogleSignInAccount? account;
      
      if (kIsWeb) {
        // Web-specific: try silent sign-in first
        account = await _googleSignIn.signInSilently();
        if (account == null) {
          account = await _googleSignIn.signIn();
        }
      } else {
        // Mobile: sign out first for clean state
        await _googleSignIn.signOut();
        account = await _googleSignIn.signIn();
      }
      
      if (account == null) {
        print('DEBUG: User cancelled Google sign-in');
        return null;
      }
      
      print('DEBUG: Got Google account: ${account.email}');
      
      final GoogleSignInAuthentication auth = await account.authentication;
      
      print('DEBUG: ID token present: ${auth.idToken != null}');
      print('DEBUG: Access token present: ${auth.accessToken != null}');
      
      // Prepare the data to send to backend
      Map<String, String> authData = {};
      
      if (auth.idToken != null) {
        authData['id_token'] = auth.idToken!;
        print('DEBUG: Using ID token for authentication');
      }
      
      if (auth.accessToken != null) {
        authData['access_token'] = auth.accessToken!;
        print('DEBUG: ${auth.idToken != null ? 'Also sending' : 'Using'} access token for authentication');
      }
      
      if (authData.isEmpty) {
        throw Exception('No authentication tokens available');
      }
      
      print('DEBUG: Sending tokens to backend...');
      
      // Send tokens to your Django backend
      final result = await ApiService.googleAuthWithTokens(tokens: authData);
      
      print('DEBUG: Backend response: $result');
      
      return result;
      
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await ApiService.logout();
      print('DEBUG: Successfully signed out');
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}