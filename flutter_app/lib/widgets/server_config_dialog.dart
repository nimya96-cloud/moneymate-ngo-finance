import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _apiService = ApiService();
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _apiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    try {
      final tempUrl = _urlController.text.trim();
      await _apiService.setBaseUrl(tempUrl);
      final stats = await _apiService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _isSuccess = true;
        _statusMessage = 'Connected! Server time: ${stats.currentTimeIst}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _isSuccess = false;
        _statusMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _save() async {
    await _apiService.setBaseUrl(_urlController.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_outlined, color: Color(0xFF047857)),
          SizedBox(width: 8),
          Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the backend FastAPI server URL. Make sure the backend app is running.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 8),
            // Presets
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://10.0.2.2:8000'),
                ),
                ActionChip(
                  label: const Text('Localhost', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://localhost:8000'),
                ),
                ActionChip(
                  label: const Text('LAN (192.168.1.X)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://192.168.1.100:8000'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isSuccess ? Colors.green.shade300 : Colors.red.shade300),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSuccess ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: const Text('Test Connection'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
