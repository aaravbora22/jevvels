import 'package:flutter/material.dart';
import 'package:jevvels/src/pages/dashboard.dart';

class SimpleForm extends StatefulWidget {
  const SimpleForm({super.key});

  @override
  State<SimpleForm> createState() => _SimpleFormState();
}

class _SimpleFormState extends State<SimpleForm> {
  final _formKey = GlobalKey<FormState>();
  String _shopName = '';
  String _location = '';
  String _currency = 'INR';
  String _totalPrice = '';
  String _makingCost = '';
  String _metalRate = '';
  String _itemDetails = '';
  DateTime? _datePurchased;
  List<String> _selectedMetals = [];
  List<String> _metals = ['Gold', 'Silver', 'Platinum'];
  String _customMetal = '';

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY'];

  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _makingCostController = TextEditingController();
  final FocusNode _totalPriceFocus = FocusNode();
  final FocusNode _makingCostFocus = FocusNode();

  @override
  void dispose() {
    _totalPriceController.dispose();
    _makingCostController.dispose();
    _totalPriceFocus.dispose();
    _makingCostFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _datePurchased) {
      setState(() {
        _datePurchased = picked;
      });
    }
  }

  void _addCustomMetal() {
    if (_customMetal.isNotEmpty) {
      setState(() {
        _metals.add(_customMetal);
        _selectedMetals.add(_customMetal);
        _customMetal = '';
      });
    }
  }

  String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'GBP':
        return '£';
      case 'USD':
        return '24';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jewellery Form'),
        backgroundColor: Colors.blue[300],
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Enter Jewellery Billing Details',
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Location Search (simulate Google Maps search)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Search Shop Location',
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSaved: (value) => _location = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    // Shop Name
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Shop Name',
                        prefixIcon: const Icon(Icons.store),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSaved: (value) => _shopName = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    // Date Purchased
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _datePurchased == null
                                ? 'Date Purchased: Not selected'
                                : 'Date Purchased: ${_datePurchased!.day}/${_datePurchased!.month}/${_datePurchased!.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Total Price with Currency
                    Text('Total Price / Amount Paid',
                        style: Theme.of(context).textTheme.titleMedium),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: _currency,
                            items: _currencies
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _currency = val ?? 'INR';
                              });
                            },
                          ),
                          const VerticalDivider(width: 24, thickness: 1),
                          Text(getCurrencySymbol(_currency)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_totalPriceController.text),
                              controller: _totalPriceController,
                              focusNode: _totalPriceFocus,
                              decoration: const InputDecoration(
                                hintText: '0000',
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onTap: () {
                                if (_totalPriceController.text == '' ||
                                    _totalPriceController.text == '0000') {
                                  setState(() {
                                    _totalPriceController.text = '';
                                  });
                                }
                              },
                              onChanged: (value) {
                                setState(() {});
                              },
                              onSaved: (value) => _totalPrice = value ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Making Cost with Currency
                    Text('Making Cost',
                        style: Theme.of(context).textTheme.titleMedium),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: _currency,
                            items: _currencies
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _currency = val ?? 'INR';
                              });
                            },
                          ),
                          const VerticalDivider(width: 24, thickness: 1),
                          Text(getCurrencySymbol(_currency)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_makingCostController.text),
                              controller: _makingCostController,
                              focusNode: _makingCostFocus,
                              decoration: const InputDecoration(
                                hintText: '0000',
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onTap: () {
                                if (_makingCostController.text == '' ||
                                    _makingCostController.text == '0000') {
                                  setState(() {
                                    _makingCostController.text = '';
                                  });
                                }
                              },
                              onChanged: (value) {
                                setState(() {});
                              },
                              onSaved: (value) => _makingCost = value ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Precious Metals Grid
                    Text('Select Precious Metals:',
                        style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8.0,
                      children: _metals.map((metal) {
                        final selected = _selectedMetals.contains(metal);
                        return FilterChip(
                          label: Text(metal),
                          selected: selected,
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                _selectedMetals.add(metal);
                              } else {
                                _selectedMetals.remove(metal);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Add Other Metal',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) => _customMetal = value,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addCustomMetal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Metal Rate
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Precious Metal Rate',
                        prefixIcon: const Icon(Icons.trending_up),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _metalRate = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    // Other Jewellery Item Details
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Other Jewellery Item Details',
                        prefixIcon: const Icon(Icons.info_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                      onSaved: (value) => _itemDetails = value ?? '',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue[400],
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final extractedInfo = {
                              'shop_name': _shopName.isEmpty ? null : _shopName,
                              'location': _location.isEmpty ? null : _location,
                              'date_purchased':
                                  _datePurchased?.toIso8601String() ?? null,
                              'currency': _currency,
                              'total_price': _totalPriceController.text.isEmpty
                                  ? null
                                  : _totalPriceController.text,
                              'making_cost': _makingCostController.text.isEmpty
                                  ? null
                                  : _makingCostController.text,
                              'precious_metals': _selectedMetals.isEmpty
                                  ? null
                                  : _selectedMetals,
                              'precious_metal_rate':
                                  _metalRate.isEmpty ? null : _metalRate,
                              'item_details':
                                  _itemDetails.isEmpty ? null : _itemDetails,
                            };
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Extracted Information'),
                                content: SingleChildScrollView(
                                  child: Text(extractedInfo.toString()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const Dashboard(),
            ),
          );
        },
        child: const Icon(Icons.arrow_back),
        backgroundColor: Colors.blue[300],
      ),
    );
  }
}
