import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => LicenseScreenState();
}

class LicenseScreenState extends State<LicenseScreen> {
  List<dynamic>? _licenses;
  String _kittenLicense =
      'Copyright KittenML\n\n'
      'Licensed under the Apache License, Version 2.0\n'
      'http://www.apache.org/licenses/LICENSE-2.0';

  Future<void> _loadLicense() async {
    final json = await rootBundle.loadString('assets/licenses.json');
    final kittenLicense = await rootBundle.loadString('assets/KITTEN_LICENSE');
    final data = jsonDecode(json) as List<dynamic>;
    setState(() {
      _licenses = data;
      _kittenLicense = kittenLicense;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('开源许可证')),
      body: _licenses == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _licenses!.length + 1,
              itemBuilder: (content, index) {
                if (index == 0) {
                  return ListTile(
                    title: Text('Kitten TTS'),
                    subtitle: Text('0.8'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LicenseDetailPage(
                            license: {
                              'name': 'KittenML/kitten-tts-nano-0.1',
                              'version': '0.1',
                              'description':
                                  'Kitten TTS is an open-source realistic text-to-speech model with just 15 million parameters, designed for lightweight deployment and high-quality voice synthesis.',
                              'license': _kittenLicense,
                              'homepage':
                                  'https://huggingface.co/KittenML/kitten-tts-nano-0.1',
                              'repository':
                                  'https://github.com/KittenML/KittenTTS',
                              'authors': [],
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  final license = _licenses![index - 1] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(license['name'] ?? ''),
                    subtitle: Text('${license['version'] ?? ''}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LicenseDetailPage(license: license),
                        ),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}

class LicenseDetailPage extends StatelessWidget {
  final Map<String, dynamic> license;
  const LicenseDetailPage({required this.license, super.key});

  @override
  Widget build(BuildContext context) {
    final name = license['name'] as String? ?? '未知';
    final version = license['version'] as String? ?? '';
    final description = license['description'] as String? ?? '';
    final homepage = license['homepage'] as String? ?? '';
    final repository = license['repository'] as String? ?? '';
    final authors =
        (license['authors'] as List<dynamic>?)?.cast<String>() ?? [];
    final licenseText = license['license'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: $version', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('主页: $homepage', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text('仓库: $repository', style: const TextStyle(fontSize: 14)),
            if (authors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('作者:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...authors.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('• $a'),
                ),
              ),
            ],
            const Divider(height: 32),
            const Text('许可证内容'),
            const SizedBox(height: 8),
            Text(
              licenseText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
