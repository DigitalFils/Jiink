import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/logo.dart';

/// The other half of the marketplace: photo, what it is, what it costs,
/// live for eight hours.
///
/// Deliberately one screen with no wizard. The whole promise is "snap it,
/// sell it" — every extra step between the camera closing and the listing
/// going live is a step where someone gives up.
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
      if (!mounted) return;
      // Pop back to the shell that pushed this, rather than building a new
      // one over the top. The old code replaced the whole navigation stack
      // with a fresh RootShell, which threw away every tab's scroll
      // position and rebuilt four screens to show a feed the listing was
      // about to stream into anyway.
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live for the next 8 hours.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't publish: $e");
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: S8llColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: S8llScreenHeading('Sell')),
                ],
              ),
              const SizedBox(height: 16),
              _Photo(path: widget.photoPath),
              const SizedBox(height: 24),
              const _FieldLabel('What is it?'),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  color: S8llColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(hintText: 'Nike Air Max 90, UK9'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Give it a name' : null,
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Price'),
              TextFormField(
                controller: _priceController,
                // The price is the loudest thing on a card, so it's the
                // loudest thing here too — you type it at the size you'll
                // see it.
                style: const TextStyle(
                  color: S8llColors.lime,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
                decoration: const InputDecoration(
                  // prefixIcon, not prefixText: Material only draws a
                  // prefix once the field has focus or content, so on the
                  // empty field you'd get an unlabelled "0" and no clue
                  // what currency you were typing.
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 16, right: 4),
                    child: Text(
                      '£',
                      style: TextStyle(
                        color: S8llColors.lime,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: S8llColors.greyLow,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // Some keyboards (Samsung's included) insert a stray space
                // after the decimal point under auto-punctuation, which
                // `double.tryParse` then rejects — block anything but
                // digits and a single '.' at the input level rather than
                // only complaining after the fact.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Set a price';
                  final pounds = double.tryParse(value.trim());
                  if (pounds == null) return 'Enter a number';
                  if (pounds <= 0) return 'Has to be more than nothing';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Category'),
              _ChipRow<ListingCategory>(
                values: ListingCategory.values,
                selected: _category,
                labelOf: (c) => c.label,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('How are you handing it over?'),
              _ChipRow<DeliveryMethod>(
                values: DeliveryMethod.values,
                selected: _delivery,
                labelOf: (d) => d.label,
                onSelect: (d) => setState(() => _delivery = d),
              ),
              if (_delivery == DeliveryMethod.meetup) ...[
                const SizedBox(height: 10),
                const Text(
                  'Meet-up only means buyers arrange it in chat — no in-app '
                  'payment, so nothing to set up.',
                  style: TextStyle(color: S8llColors.grey, fontSize: 12, height: 1.4),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, style: const TextStyle(color: S8llColors.error)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _publishing ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(S8llRadius.md),
                    ),
                  ),
                  child: Text(_publishing ? 'Publishing…' : 'Publish now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo, with the one rule that matters stated on top of it: eight
/// hours from the moment you tap publish.
class _Photo extends StatelessWidget {
  const _Photo({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              // The OS can evict a camera capture from its temp directory
              // before publish finishes. Losing the photo should not mean
              // a grey crash box where the listing preview goes.
              errorBuilder: (context, error, stack) => Container(
                color: S8llColors.charcoalHigh,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: S8llColors.greyLow, size: 40),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: S8llColors.greyLow,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Wrapping chips rather than a dropdown or a SegmentedButton: it's the
/// same control the feed uses for categories, every option is visible
/// without a tap, and it doesn't fall over when the labels are long.
class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onSelect(value),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: value == selected ? S8llColors.lime : S8llColors.charcoal,
                borderRadius: BorderRadius.circular(S8llRadius.pill),
              ),
              child: Text(
                labelOf(value),
                style: TextStyle(
                  color: value == selected ? S8llColors.black : S8llColors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
