import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  int? _selectedMarkerIndex;
  final List<MapMarker> _markers = [
    MapMarker(
      id: '1',
      title: 'Adidas Campus',
      price: 85,
      distance: '1.2mi',
      x: 0.3,
      y: 0.35,
      image: 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=200',
    ),
    MapMarker(
      id: '2',
      title: 'Nike Jacket',
      price: 95,
      distance: '0.8mi',
      x: 0.55,
      y: 0.25,
      image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=200',
    ),
    MapMarker(
      id: '3',
      title: 'Stussy Hoodie',
      price: 142,
      distance: '2.1mi',
      x: 0.7,
      y: 0.55,
      image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=200',
    ),
    MapMarker(
      id: '4',
      title: 'Vintage Camera',
      price: 320,
      distance: '0.5mi',
      x: 0.2,
      y: 0.65,
      image: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=200',
    ),
    MapMarker(
      id: '5',
      title: 'Leather Bag',
      price: 95,
      distance: '1.5mi',
      x: 0.8,
      y: 0.75,
      image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=200',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildMapBackground(),
            _buildMarkers(),
            _buildTopBar(),
            if (_selectedMarkerIndex != null) _buildSelectedCard(),
            _buildBottomList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
        ),
        child: CustomPaint(
          painter: MapPainter(),
        ),
      ),
    );
  }

  Widget _buildMarkers() {
    return Stack(
      children: _markers.asMap().entries.map((entry) {
        final index = entry.key;
        final marker = entry.value;
        final isSelected = _selectedMarkerIndex == index;
        return Positioned(
          left: MediaQuery.of(context).size.width * marker.x - 28,
          top: MediaQuery.of(context).size.height * marker.y - 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedMarkerIndex = isSelected ? null : index),
            child: AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: AppAnimations.fast,
              curve: AppAnimations.bounce,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.accent : AppTheme.border,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Text(
                      '£${marker.price}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppTheme.background : AppTheme.accent,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 8,
                    color: isSelected ? AppTheme.accent : AppTheme.border,
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accent : AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accent, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.accent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Manchester, UK',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.layers, color: AppTheme.textPrimary),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard() {
    final marker = _markers[_selectedMarkerIndex!];
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Dismissible(
        key: Key(marker.id),
        direction: DismissDirection.up,
        onDismissed: (_) => setState(() => _selectedMarkerIndex = null),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Image.network(
                    marker.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.surfaceLight);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          marker.distance,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '£${marker.price}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomList() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppTheme.background.withOpacity(0.9),
              AppTheme.background,
            ],
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          itemCount: SampleData.products.length,
          itemBuilder: (context, index) {
            final product = SampleData.products[index];
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: AppTheme.surfaceLight);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '£${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accent,
                              ),
                            ),
                            Text(
                              '${(index + 1) * 0.3}mi',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class MapMarker {
  final String id;
  final String title;
  final double price;
  final String distance;
  final double x;
  final double y;
  final String image;

  MapMarker({
    required this.id,
    required this.title,
    required this.price,
    required this.distance,
    required this.x,
    required this.y,
    required this.image,
  });
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1A2332)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFF0E1A2A)
      ..style = PaintingStyle.fill;

    final parkPaint = Paint()
      ..color = const Color(0xFF0F1F14)
      ..style = PaintingStyle.fill;

    // Water areas
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.1, 100, 80),
        const Radius.circular(20),
      ),
      waterPaint,
    );

    // Parks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.5, 80, 60),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // Roads - horizontal
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.1 + i * 0.12);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i % 2 == 0 ? 20 : -10)),
        roadPaint,
      );
    }

    // Roads - vertical
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.1 + i * 0.18);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (i % 2 == 0 ? 15 : -15), size.height),
        roadPaint,
      );
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF121821)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 20; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 20),
        Offset(size.width, size.height * i / 20),
        gridPaint,
      );
      canvas.drawLine(
        Offset(size.width * i / 20, 0),
        Offset(size.width * i / 20, size.height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
