import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../models/google_sign_in_result.dart';

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn, Uuid? uuid})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            ),
        _uuid = uuid ?? const Uuid();

  final GoogleSignIn _googleSignIn;
  final Uuid _uuid;

  Future<GoogleSignInResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const GoogleSignInResult(cancelled: true);
      }

      final auth = await account.authentication;
      final email = _resolveEmail(account);
      final displayName = account.displayName?.trim();

      return GoogleSignInResult(
        idToken: auth.idToken,
        email: email,
        displayName: displayName?.isNotEmpty == true ? displayName : null,
        googleId: account.id,
      );
    } catch (error) {
      return GoogleSignInResult(errorMessage: error.toString());
    }
  }

  String buildSandboxToken({
    required String email,
    required String fullName,
  }) {
    final googleId = _uuid.v4().replaceAll('-', '');
    final safeName = fullName.trim().replaceAll(' ', '');
    return 'sandbox_${googleId}_${email.trim()}_$safeName';
  }

  String _resolveEmail(GoogleSignInAccount account) {
    final email = account.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    final googleId = account.id.trim().replaceAll(' ', '');
    if (googleId.isNotEmpty) {
      return '$googleId@gmail.com';
    }

    return '${_uuid.v4().replaceAll('-', '')}@gmail.com';
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
