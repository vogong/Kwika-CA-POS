import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _currencySymbolController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _taxRateController;
  late TextEditingController _taxNameController;
  late bool _taxInclusive;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsState>().settings;
    _currencySymbolController = TextEditingController(text: settings.currencySymbol);
    _currencyCodeController = TextEditingController(text: settings.currencyCode);
    _taxRateController = TextEditingController(text: settings.taxRate.toString());
    _taxNameController = TextEditingController(text: settings.taxName);
    _taxInclusive = settings.taxInclusive;
  }

  @override
  void dispose() {
    _currencySymbolController.dispose();
    _currencyCodeController.dispose();
    _taxRateController.dispose();
    _taxNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Currency Settings Section
              const Text(
                'Currency Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currencySymbolController,
                      decoration: const InputDecoration(
                        labelText: 'Currency Symbol',
                        hintText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a currency symbol';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Currency Code',
                        hintText: 'USD',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a currency code';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tax Settings Section
              const Text(
                'Tax Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate (%)',
                        hintText: '13.0',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tax rate';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate < 0 || rate > 100) {
                          return 'Please enter a valid tax rate (0-100)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _taxNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Name',
                        hintText: 'HST',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a tax name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tax Inclusive Pricing'),
                subtitle: const Text(
                  'When enabled, product prices include tax',
                ),
                value: _taxInclusive,
                onChanged: (bool value) {
                  setState(() {
                    _taxInclusive = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = context.read<SettingsState>();
      settings.updateSettings(
        currencySymbol: _currencySymbolController.text,
        currencyCode: _currencyCodeController.text,
        taxRate: double.parse(_taxRateController.text),
        taxInclusive: _taxInclusive,
        taxName: _taxNameController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
