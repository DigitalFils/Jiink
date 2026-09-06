import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'root_shell.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key, required this.photoPath});

  final String photoPath;

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  DeliveryMethod _delivery = DeliveryMethod.both;
  ListingCategory _category = ListingCategory.other;
  bool _publishing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final pounds = double.parse(_priceController.text.trim());
      await context.read<AppState>().publishListing(
            title: _titleController.text.trim(),
            priceCents: (pounds * 100).round(),
            delivery: _delivery,
            photo: File(widget.photoPath),
            category: _category,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootShell()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = "Couldn't publish: $e");
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(S8llRadius.lg),
                child: Stack(
                  children: [
                    Image.file(
                      File(widget.photoPath),
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Says the actual rule up front rather than after the
                    // fact: publishing starts an 8-hour clock, and that's
                    // the whole mechanic.
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: S8llColors.lime,
                          borderRadius: BorderRadius.circular(S8llRadius.pill),
                        ),
                        child: const Text(
                          'Goes live for 8h',
                          style: TextStyle(
                            color: S8llColors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'What is it?'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '£ ',
                  prefixStyle: TextStyle(
                    color: S8llColors.lime,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // Some keyboards (Samsung's included) insert a stray space
                // after the decimal point under auto-punctuation, which
                // `double.tryParse` then rejects — block anything but
                // digits and a single '.' at the input level instead of
                // just validating after the fact.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (double.tryParse(value.trim()) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ListingCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in ListingCategory.values)
                    DropdownMenuItem(value: category, child: Text(category.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<DeliveryMethod>(
                segments: const [
                  ButtonSegment(value: DeliveryMethod.meetup, label: Text('Meet up')),
                  ButtonSegment(value: DeliveryMethod.shipping, label: Text('Ship')),
                  ButtonSegment(value: DeliveryMethod.both, label: Text('Both')),
                ],
                selected: {_delivery},
                onSelectionChanged: (selection) => setState(() => _delivery = selection.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _publishing ? null : _publish,
                child: Text(_publishing ? 'Publishing…' : 'Publish now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
