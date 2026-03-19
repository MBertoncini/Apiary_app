import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Small "?" icon that shows an info dialog on tap.
/// Usage: Row(children: [Text('Label'), FieldHelpIcon('Spiegazione...')])
class FieldHelpIcon extends StatelessWidget {
  final String helpText;

  const FieldHelpIcon(this.helpText, {super.key});

  static const Color _primary = Color(0xFFD3A121);
  static const Color _dark = Color(0xFF3A2E21);
  static const Color _border = Color(0xFFEAD9BF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHelp(context),
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: _border,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '?',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFF8F5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                child: const Center(
                  child: Text('?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                helpText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13.5, color: _dark, height: 1.6),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Capito', style: GoogleFonts.poppins(color: _primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
