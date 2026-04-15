import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../services/language_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _header(s.privacyHeader),
          _updated(s.privacyLastUpdated),
          _highlight(s.privacyIntro),
          _h2(s.privacyS1Title),
          _body(s.privacyS1Body),
          _emailLink('michele.bertoncini@gmail.com'),
          _h2(s.privacyS2Title),
          _body(s.privacyS2Body),
          _h2(s.privacyS2_1Title),
          _bullets(s.privacyS2_1Bullets),
          _h2(s.privacyS2_2Title),
          _bullets(s.privacyS2_2Bullets),
          _h2(s.privacyS2_3Title),
          _body(s.privacyS2_3Body),
          _h2(s.privacyS3Title),
          _bullets(s.privacyS3Bullets),
          _h2(s.privacyS4Title),
          _bullets(s.privacyS4Bullets),
          _h2(s.privacyS5Title),
          _bullets(s.privacyS5Bullets),
          _h2(s.privacyS6Title),
          _body(s.privacyS6Body),
          _bullets(s.privacyS6Bullets),
          _h2(s.privacyS7Title),
          _body(s.privacyS7Body),
          _bullets(s.privacyS7Bullets),
          _body(s.privacyS7Contact),
          _emailLink('michele.bertoncini@gmail.com'),
          _body(s.privacyS7Garante),
          _urlLink('www.garanteprivacy.it', 'https://www.garanteprivacy.it'),
          _h2(s.privacyS8Title),
          _body(s.privacyS8Body),
          _h2(s.privacyS9Title),
          _body(s.privacyS9Body),
          _h2(s.privacyS10Title),
          _body(s.privacyS10Body),
          _h2(s.privacyS11Title),
          _body(s.privacyS11Body),
          _emailLink('michele.bertoncini@gmail.com'),
          const SizedBox(height: 32),
          Text(
            s.privacyCopyright,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      );

  Widget _updated(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      );

  Widget _highlight(String text) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F5E9),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          border: Border(left: BorderSide(color: Color(0xFF2E7D32), width: 4)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
      );

  Widget _h2(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
      );

  Widget _bullets(List<String> items) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                            child: Text(item,
                                style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _emailLink(String email) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse('mailto:$email')),
          child: Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E7D32),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );

  Widget _urlLink(String label, String url) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E7D32),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
}
