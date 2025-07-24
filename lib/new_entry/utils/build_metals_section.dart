import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef MetalsChanged = void Function(List<Map<String, String?>> metals);

class BuildMetalsSection extends StatefulWidget {
  final MetalsChanged? onMetalsChanged;
  const BuildMetalsSection({super.key, this.onMetalsChanged});

  @override
  State<BuildMetalsSection> createState() => _BuildMetalsSectionState();
}

class _BuildMetalsSectionState extends State<BuildMetalsSection> {
  List<Map<String, String?>> metalEntries = [
    {'metal': null, 'weight': null, 'karat': null},
  ];

  void _notifyParent() {
    if (widget.onMetalsChanged != null) {
      widget.onMetalsChanged!(List<Map<String, String?>>.from(metalEntries));
    }
  }

  Widget _buildMetalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metals Used',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
              fontSize: 24),
        ),
        const SizedBox(height: 10),
        ...metalEntries.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String?> metal = entry.value;

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: BuildTextField(
                      label: 'Metal',
                      initialValue: metal['metal'],
                      onChanged: (val) {
                        metal['metal'] = val;
                        _notifyParent();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildTextField(
                      label: 'Weight (g)',
                      initialValue: metal['weight'],
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        metal['weight'] = val;
                        _notifyParent();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BuildTextField(
                      label: 'Karat/Purity',
                      initialValue: metal['karat'],
                      onChanged: (val) {
                        metal['karat'] = val;
                        _notifyParent();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        metalEntries.removeAt(index);
                        _notifyParent();
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                  )
                ],
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                metalEntries
                    .add({'metal': null, 'weight': null, 'karat': null});
                _notifyParent();
              });
            },
            icon: const Icon(Icons.add, color: Color(0xFFB99750)),
            label: const Text('Add Metal',
                style: TextStyle(
                    color: Color(0xFFB99750),
                    fontFamily: 'Main Font',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMetalSection();
  }
}
