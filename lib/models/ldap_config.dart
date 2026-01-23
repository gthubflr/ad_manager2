class LdapConfig {
  final String server;
  final String domain;
  final String username;
  final String password;
  final bool useSSL;
  final bool validateCertificate;
  final int? port;
  final String? caCertAssetPath;
  final String? customCaCert;

  LdapConfig({
    required this.server,
    required this.domain,
    required this.username,
    required this.password,
    this.useSSL = true,
    this.validateCertificate = true,
    this.port,
    this.caCertAssetPath,
    this.customCaCert,
  });

  LdapConfig copyWith({
    String? server,
    String? domain,
    String? username,
    String? password,
    bool? useSSL,
    bool? validateCertificate,
    int? port,
    String? caCertAssetPath,
    String? customCaCert,
  }) {
    return LdapConfig(
      server: server ?? this.server,
      domain: domain ?? this.domain,
      username: username ?? this.username,
      password: password ?? this.password,
      useSSL: useSSL ?? this.useSSL,
      validateCertificate: validateCertificate ?? this.validateCertificate,
      port: port ?? this.port,
      caCertAssetPath: caCertAssetPath ?? this.caCertAssetPath,
      customCaCert: customCaCert ?? this.customCaCert,
    );
  }
}