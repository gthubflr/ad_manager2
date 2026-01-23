import 'dart:io';
import 'package:flutter/services.dart';

class LdapSecurity {
  static Future<SecurityContext> createContext() async {
    final context = SecurityContext(withTrustedRoots: false);

    final data = await rootBundle.load('assets/certs/ca-root.pem');
    context.setTrustedCertificatesBytes(
      data.buffer.asUint8List(),
    );

    return context;
  }
}
