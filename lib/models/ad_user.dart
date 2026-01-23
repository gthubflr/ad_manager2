class ADUser {
final String username;
  final String displayName;
  final String email;
  final bool isEnabled;
  final bool isLocked;
  final String? lastLogon;
  final String distinguishedName;
  final String? mail;
  final String? samAccountName;
  final String? telephoneNumber;
  // NEU:
  final Map<String, dynamic> attributes;

  ADUser({
    required this.username,
    required this.displayName,
    required this.email,
    required this.isEnabled,
    required this.isLocked,
    this.lastLogon,
    required this.distinguishedName,
    this.mail,
    this.samAccountName,
    this.telephoneNumber,
    this.attributes = const {}, // Standardmäßig leere Map
  });

  /// Erstellt eine Kopie des Benutzers mit optional geänderten Werten
  ADUser copyWith({
    String? username,
    String? displayName,
    String? email,
    bool? isEnabled,
    bool? isLocked,
    String? lastLogon,
    String? distinguishedName,
  }) {
    return ADUser(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      lastLogon: lastLogon ?? this.lastLogon,
      distinguishedName: distinguishedName ?? this.distinguishedName,
    );
  }

  factory ADUser.fromMap(Map<String, dynamic> map) => ADUser(
        username: map['username'] ?? '',
        displayName: map['displayName'] ?? '',
        email: map['email'] ?? '',
        isEnabled: map['isEnabled'] ?? false,
        isLocked: map['isLocked'] ?? false,
        lastLogon: map['lastLogon'],
        distinguishedName: map['dn'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'displayName': displayName,
        'email': email,
        'isEnabled': isEnabled,
        'isLocked': isLocked,
        'lastLogon': lastLogon,
        'dn': distinguishedName,
      };
}