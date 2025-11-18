import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef MetalsChanged = void Function(List<Map<String, String?>> metals);

class BuildMetalsSection extends StatelessWidget {
  final MetalsChanged? onMetalsChanged;
  final List<Map<String, String?>> metals;

  const BuildMetalsSection({
    super.key,
    this.onMetalsChanged,
    required this.metals,
  });

  void _updateMetal(int index, String field, String value) {
    if (onMetalsChanged == null) return;

    final updated = List<Map<String, String?>>.from(metals);
    updated[index] = Map<String, String?>.from(updated[index])
      ..[field] = value;
    onMetalsChanged!(updated);
  }

  void _addMetal() {
    if (onMetalsChanged == null) return;

    final updated = List<Map<String, String?>>.from(metals)
      ..add({'metal': null, 'weight': null, 'karat': null});
    onMetalsChanged!(updated);
  }

  void _removeMetal(int index) {
    if (onMetalsChanged == null) return;

    final updated = List<Map<String, String?>>.from(metals)..removeAt(index);
    onMetalsChanged!(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metals Used',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Main Font',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 10),
        ...metals.asMap().entries.map((entry) {
          final index = entry.key;
          final metal = entry.value;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: BuildTextField(
                      label: 'Metal',
                      initialValue: metal['metal'],
                      onChanged: (val) => _updateMetal(index, 'metal', val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildTextField(
                      label: 'Weight (g)',
                      initialValue: metal['weight'],
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateMetal(index, 'weight', val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildTextField(
                      label: 'Karat/Purity',
                      initialValue: metal['karat'],
                      onChanged: (val) => _updateMetal(index, 'karat', val),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeMetal(index),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addMetal,
            icon: const Icon(Icons.add, color: Color(0xFFB99750)),
            label: const Text(
              'Add Metal',
              style: TextStyle(
                color: Color(0xFFB99750),
                fontFamily: 'Main Font',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
