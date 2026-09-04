import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
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
      final pounds = double.parse(_priceController.text);
      await context.read<AppState>().publishListing(
            title: _titleController.text.trim(),
            priceCents: (pounds * 100).round(),
            delivery: _delivery,
            photo: File(widget.photoPath),
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
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.photoPath),
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'What is it?'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (£)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Enter a number';
                  return null;
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
