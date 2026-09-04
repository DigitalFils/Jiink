import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../widgets/listing_photo.dart';
import 'feed_screen.dart';

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

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().publishListing(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text),
          delivery: _delivery,
          photoPath: widget.photoPath,
        );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FeedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewListing = Listing(
      id: 'preview',
      title: '',
      price: 0,
      seller: currentUser,
      delivery: _delivery,
      postedAt: DateTime.now(),
      photoPath: widget.photoPath,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Publish')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListingPhoto(listing: previewListing, height: 260),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _publish,
                child: const Text('Publish now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
