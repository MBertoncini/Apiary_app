import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class ApiarioFilterRow extends StatelessWidget {
  final List<dynamic> apiari;
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onSelectAll;

  const ApiarioFilterRow({
    Key? key,
    required this.apiari,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allActive = selected.isEmpty;
    return Container(
      height: 52,
      color: ThemeConstants.primaryColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('Tutti'),
              selected: allActive,
              showCheckmark: false,
              onSelected: (_) => onSelectAll(),
              backgroundColor: Colors.white.withOpacity(0.15),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: allActive
                    ? ThemeConstants.secondaryColor
                    : ThemeConstants.textPrimaryColor.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(
                color: Colors.white.withOpacity(allActive ? 1.0 : 0.4),
              ),
            ),
          ),
          ...apiari.map((a) {
            final id = a['id'] as int;
            final isSel = selected.contains(id);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(a['nome'] as String),
                selected: isSel,
                showCheckmark: false,
                onSelected: (_) => onToggle(id),
                backgroundColor: Colors.white.withOpacity(0.15),
                selectedColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSel
                      ? ThemeConstants.secondaryColor
                      : ThemeConstants.textPrimaryColor.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: Colors.white.withOpacity(isSel ? 1.0 : 0.4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
