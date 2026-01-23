import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/ldap_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller
  final _serverController = TextEditingController();
  final _domainController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();
  final _caCertController = TextEditingController();

  // State Flags
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useSSL = true;
  bool _validateCertificate = true;
  bool _showAdvanced = false;
  bool _showCaCertInput = false;
  
  // Merker, damit wir die Felder nicht ständig überschreiben
  bool _initialFieldsPopulated = false;

  @override
  void initState() {
    super.initState();
    _portController.text = '636';
  }

  @override
  void dispose() {
    _serverController.dispose();
    _domainController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _caCertController.dispose();
    super.dispose();
  }

  /// Füllt alle Felder aus der Config, AUSSER dem Passwort
  void _fillFields(LdapConfig config) {
    if (_initialFieldsPopulated) return;

    _serverController.text = config.server;
    _domainController.text = config.domain;
    _usernameController.text = config.username;
    
    // Passwort bleibt explizit leer
    _passwordController.text = ''; 
    
    _useSSL = config.useSSL;
    _validateCertificate = config.validateCertificate;
    _portController.text = (config.port ?? (config.useSSL ? 636 : 389)).toString();
    _caCertController.text = config.customCaCert ?? '';
    
    _showCaCertInput = config.customCaCert != null && config.customCaCert!.isNotEmpty;
    
    // Automatisches Aufklappen der erweiterten Einstellungen, falls nötig
    if (_showCaCertInput || !_validateCertificate || (config.port != 636 && config.port != 389)) {
      _showAdvanced = true;
    }
    
    _initialFieldsPopulated = true;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final config = LdapConfig(
      server: _serverController.text.trim(),
      domain: _domainController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useSSL: _useSSL,
      validateCertificate: _validateCertificate,
      port: int.tryParse(_portController.text),
      customCaCert: _caCertController.text.trim().isEmpty ? null : _caCertController.text.trim(),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Wir übergeben savePassword: false, da das PW nie gespeichert werden soll
    final success = await authProvider.login(config, savePassword: false);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) _showErrorDialog(authProvider.errorMessage ?? 'Unbekannter Fehler');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.error_outline, color: Colors.red), SizedBox(width: 8), Text('Login fehlgeschlagen')],
        ),
        content: SingleChildScrollView(child: SelectableText(message, style: const TextStyle(fontFamily: 'monospace'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Wenn Daten vom Provider (SharedPrefs) kommen, Felder füllen
        if (auth.config != null && !_initialFieldsPopulated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _fillFields(auth.config!));
          });
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 80, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 24),
                      Text('AD Manager', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      
                      _buildTextField(_serverController, 'LDAP Server *', Icons.dns, 'Hostname oder IP'),
                      const SizedBox(height: 16),
                      _buildTextField(_domainController, 'Domain *', Icons.domain, 'z.B. corp.local'),
                      const SizedBox(height: 16),
                      _buildTextField(_usernameController, 'Benutzername *', Icons.person, 'z.B. Administrator'),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Passwort *',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Passwort fehlt' : null,
                      ),
                      
                      const SizedBox(height: 8),

                      ExpansionTile(
                        title: const Text('Erweiterte Einstellungen'),
                        leading: const Icon(Icons.settings),
                        initiallyExpanded: _showAdvanced,
                        children: [
                          SwitchListTile(
                            title: const Text('SSL/TLS (LDAPS)'),
                            value: _useSSL,
                            onChanged: (val) => setState(() {
                              _useSSL = val;
                              _portController.text = val ? '636' : '389';
                            }),
                          ),
                          SwitchListTile(
                            title: const Text('Zertifikat validieren'),
                            value: _validateCertificate,
                            onChanged: (val) => setState(() => _validateCertificate = val),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: TextFormField(
                              controller: _portController,
                              decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          ListTile(
                            title: const Text('Eigenes CA-Zertifikat'),
                            trailing: Icon(_showCaCertInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                            onTap: () => setState(() => _showCaCertInput = !_showCaCertInput),
                          ),
                          if (_showCaCertInput)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                controller: _caCertController,
                                decoration: const InputDecoration(labelText: 'CA-Zertifikat (PEM)', border: OutlineInputBorder()),
                                maxLines: 5,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _login,
                        icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Icon(Icons.login),
                        label: Text(_isLoading ? 'Verbinde...' : 'Anmelden'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String helper) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon), 
        helperText: helper, 
        border: const OutlineInputBorder()
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Pflichtfeld' : null,
    );
  }
}