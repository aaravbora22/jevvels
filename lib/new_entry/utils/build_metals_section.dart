import 'package:flutter/material.dart';
import 'package:jevvels/widgets/build_text_field.dart';

typedef MetalsChanged = void Function(List<Map<String, dynamic>> metals);

class BuildMetalsSection extends StatefulWidget {
  final MetalsChanged? onMetalsChanged;
  final List<Map<String, dynamic>>? metals;

  const BuildMetalsSection({
    super.key,
    this.onMetalsChanged,
    this.metals,
  });

  @override
  State<BuildMetalsSection> createState() => _BuildMetalsSectionState();
}

class _BuildMetalsSectionState extends State<BuildMetalsSection> {
  // Preset options
  static const List<String> _metalOptions = [
    'Gold',
    'Silver',
    'Platinum',
    'Copper',
    'Zinc',
    'Other',
  ];

  static const List<String> _goldKaratOptions = [
    '16',
    '18',
    '20',
    '22',
    '24',
  ];

  static const List<String> _purityOptions = [
    '999',
    '995',
    '990',
    '958',
    '950',
    '925',
  ];

  late List<Map<String, dynamic>> metalEntries;

  @override
  void initState() {
    super.initState();
    metalEntries = widget.metals ??
        [
          {
            "metal": null,
            "weight": null,
            "is_karat": true,
            "karat": null,
            "purity": null,
          }
        ];
  }

  void _notifyParent() {
    widget.onMetalsChanged?.call(List<Map<String, dynamic>>.from(metalEntries));
  }

  void _autoDetectMode(Map<String, dynamic> metal) {
    final type = (metal["metal"] ?? "").toString().toLowerCase();

    if (type.contains("gold")) {
      metal["is_karat"] = true; // Gold uses karat
      metal["purity"] = null;
    } else if (type.contains("silver") || type.contains("platinum")) {
      metal["is_karat"] = false; // Silver + Platinum use purity
      metal["karat"] = null;
    } else {
      // Other metals → default to purity style numbers
      metal["is_karat"] = false;
      metal["karat"] = null;
    }
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2C2B2B),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB99750)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB99750), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
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

        ...metalEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final metal = entry.value;

          final String? selectedMetal = _metalOptions.contains(metal["metal"])
              ? metal["metal"]
              : null;

          final bool isKarat = metal["is_karat"] == true;

          return Column(
            children: [
              // Row 1: Metal + Weight
              Row(
                children: [
                  // 🔹 Metal dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Metal',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: selectedMetal,
                          dropdownColor: const Color(0xFF2C2B2B),
                          decoration: _dropdownDecoration(),
                          iconEnabledColor: const Color(0xFFB99750),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                          items: _metalOptions
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              metal["metal"] = val;
                              _autoDetectMode(metal);
                              _notifyParent();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 🔹 Weight text field
                  Expanded(
                    child: BuildTextField(
                      label: 'Weight (g)',
                      initialValue: metal["weight"],
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        metal["weight"] = v;
                        _notifyParent();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 2: Karat/Purity mode + Karat/Purity dropdown
              Row(
                children: [
                  // Mode selector (Karat / Purity)
                  DropdownButton<bool>(
                    value: isKarat,
                    dropdownColor: const Color(0xFF2C2B2B),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Main Font',
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text("Karat")),
                      DropdownMenuItem(value: false, child: Text("Purity")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        metal["is_karat"] = value;
                        metal["karat"] = null;
                        metal["purity"] = null;
                        _notifyParent();
                      });
                    },
                  ),

                  const SizedBox(width: 12),

                  // Karat or Purity dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKarat ? 'Karat' : 'Purity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: isKarat ? metal["karat"] : metal["purity"],
                          dropdownColor: const Color(0xFF2C2B2B),
                          decoration: _dropdownDecoration(),
                          iconEnabledColor: const Color(0xFFB99750),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Main Font',
                            fontWeight: FontWeight.bold,
                          ),
                          items: (isKarat ? _goldKaratOptions : _purityOptions)
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              if (isKarat) {
                                metal["karat"] = val;
                              } else {
                                metal["purity"] = val;
                              }
                              _notifyParent();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () {
                      setState(() {
                        metalEntries.removeAt(index);
                        _notifyParent();
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          );
        }),

        TextButton.icon(
          onPressed: () {
            setState(() {
              metalEntries.add({
                "metal": null,
                "weight": null,
                "is_karat": true,
                "karat": null,
                "purity": null,
              });
              _notifyParent();
            });
          },
          icon: const Icon(Icons.add, color: Color(0xFFB99750)),
          label: const Text(
            "Add Metal",
            style: TextStyle(
              color: Color(0xFFB99750),
              fontFamily: 'Main Font',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
