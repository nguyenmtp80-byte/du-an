import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/sandbox_google_sheet.dart';

Future<String?> _resolveSandboxToken(
  BuildContext context,
  AuthProvider auth, {
  String? email,
  String? displayName,
  bool manualEntry = false,
}) async {
  if (email != null &&
      email.isNotEmpty &&
      displayName != null &&
      displayName.isNotEmpty &&
      !manualEntry) {
    return auth.googleAuthService.buildSandboxToken(
      email: email,
      fullName: displayName,
    );
  }

  return SandboxGoogleSheet.show(
    context,
    email: email,
    initialName: displayName,
    manualEntry: manualEntry || email == null || email.isEmpty,
  );
}

Future<void> handleGoogleSignIn(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  auth.clearError();

  final result = await auth.googleAuthService.signIn();
  if (!context.mounted) {
    return;
  }

  if (result.cancelled) {
    return;
  }

  String? idToken = result.idToken;
  final googleFailed = result.errorMessage != null || !result.hasAccount;

  if (googleFailed) {
    idToken = await _resolveSandboxToken(context, auth, manualEntry: true);
  } else if (idToken == null || idToken.isEmpty) {
    idToken = await _resolveSandboxToken(
      context,
      auth,
      email: result.email,
      displayName: result.displayName,
    );
  }

  if (!context.mounted || idToken == null || idToken.isEmpty) {
    return;
  }

  final success = await auth.googleLogin(idToken: idToken);
  if (!context.mounted || success) {
    return;
  }

  if (auth.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage!)),
    );
  }
}
