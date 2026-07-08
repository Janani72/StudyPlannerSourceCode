import 'package:flutter/material.dart';
import '../ui_helpers.dart';
import '../storage_service.dart';
import '../services/secure_storage.dart';
import 'app_widget.dart';

class SettingsPage extends StatefulWidget {
  final SmartStudyPlannerAppState parent;
  const SettingsPage({super.key, required this.parent});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasToken = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    setState(() => _isLoading = true);
    _hasToken = await SecureStorage.hasToken();
    setState(() => _isLoading = false);
  }

  Future<void> _showTokenDialog() async {
    final controller = TextEditingController();
    final currentToken = await SecureStorage.getToken();
    if (currentToken != null) {
      controller.text = currentToken;
    }

    bool obscureText = true;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('GitHub Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your GitHub Personal Access Token here.\n\n'
                    '1. Go to GitHub.com → Settings → Developer settings\n'
                    '2. Personal access tokens → Tokens (classic)\n'
                    '3. Generate new token (classic)\n'
                    '4. Select "public_repo" scope\n'
                    '5. Copy and paste the token below',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'GitHub Token',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                obscureText: obscureText,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final token = controller.text.trim();
                if (token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid token')),
                  );
                  return;
                }
                await SecureStorage.saveToken(token);
                _checkToken();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Token saved securely!')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Token'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteToken() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Token?'),
        content: const Text('Are you sure you want to remove your GitHub token? '
            'AI features will stop working.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SecureStorage.deleteToken();
      _checkToken();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              // ============ GITHUB TOKEN SETTINGS ============
              ListTile(
                leading: Icon(
                  _isLoading
                      ? Icons.hourglass_empty
                      : (_hasToken ? Icons.check_circle : Icons.key),
                  color: _isLoading
                      ? Colors.grey
                      : (_hasToken ? Colors.green : Colors.orange),
                ),
                title: const Text('GitHub Token'),
                subtitle: Text(
                  _isLoading
                      ? 'Loading...'
                      : (_hasToken
                      ? '✅ Token is set - AI features are ready!'
                      : '⚠️ Token not set - AI features disabled'),
                ),
                onTap: _showTokenDialog,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hasToken)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _deleteToken,
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showTokenDialog,
                    ),
                  ],
                ),
              ),
              const Divider(),

              // ============ STREAK DEMO ============
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Increase Streak (demo)'),
                onTap: () async {
                  widget.parent.streak += 1;
                  await StorageService.setStreak(widget.parent.streak);
                  if (mounted) {
                    (context as Element).markNeedsBuild();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Streak: ${widget.parent.streak}')),
                    );
                  }
                },
              ),
              const Divider(),

              // ============ RELOAD ============
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reload data'),
                onTap: widget.parent.loadApp,
              ),
              const Divider(),

              // ============ LOGOUT ============
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Log out', style: TextStyle(color: Colors.red)),
                onTap: widget.parent.onLogout,
              ),
            ],
          ),
        ),

        // ============ HELP CARD ============
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 How to get your GitHub Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Go to GitHub.com → Settings → Developer settings\n'
                    '2. Personal access tokens → Tokens (classic)\n'
                    '3. Generate new token (classic)\n'
                    '4. Select "public_repo" scope\n'
                    '5. Copy and paste the token above',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _hasToken ? Icons.check_circle : Icons.warning,
                    color: _hasToken ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasToken
                        ? '✅ AI features are ready to use!'
                        : '⚠️ Token required for AI features',
                    style: TextStyle(
                      color: _hasToken ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}