class GoogleSignInResult {
  const GoogleSignInResult({
    this.idToken,
    this.email,
    this.displayName,
    this.googleId,
    this.cancelled = false,
    this.errorMessage,
  });

  final String? idToken;
  final String? email;
  final String? displayName;
  final String? googleId;
  final bool cancelled;
  final String? errorMessage;

  bool get hasAccount =>
      !cancelled &&
      errorMessage == null &&
      ((email != null && email!.isNotEmpty) ||
          (googleId != null && googleId!.isNotEmpty));
}
