/// Holds the access + refresh tokens.
///
/// In-memory for now. For release, back the mobile app with
/// `flutter_secure_storage` and the web portal with an httpOnly cookie
/// or session storage — only this class changes.
class TokenStore {
  String? accessToken;
  String? refreshToken;

  bool get hasSession => accessToken != null;

  void save({required String access, required String refresh}) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
