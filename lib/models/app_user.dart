import 'dart:convert';

class AppUser {
  final String uid;
  final String? displayName;
  final String? email;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
      };

  factory AppUser.fromJson(Map<String, dynamic> data) {
    return AppUser(
      uid: (data['uid'] ?? '').toString(),
      displayName: data['displayName']?.toString(),
      email: data['email']?.toString(),
    );
  }

  String encode() => jsonEncode(toJson());

  static AppUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}