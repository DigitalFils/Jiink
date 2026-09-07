import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ARTryOnScreen extends StatefulWidget {
  const ARTryOnScreen({super.key});

  @override
  State<ARTryOnScreen> createState() => _ARTryOnScreenState();
}

class _ARTryOnScreenState extends State<ARTryOnScreen> with SingleTickerProviderStateMixin {
  int _selectedShoeIndex = 0;
  double _shoeScale = 1.0;
  double _shoeRotation = 0.0;
  Offset _shoeOffset = Offset.zero;
  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;
  late AnimationController _scanController;
  bool _isScanning = true;
  bool _footDetected = false;

  final List<ARShoe> _shoes = [
    ARShoe(
      name: 'Nike Dunk Low Panda',
      color: 'Black/White',
      price: 129,
      image: 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=400',
    ),
    ARShoe(
      name: 'Adidas Samba OG',
      color: 'Cloud White',
      price: 89,
      image: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400',
    ),
    ARShoe(
      name: 'New Balance 550',
      color: 'White/Green',
      price: 110,
      image: 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=400',
    ),
    ARShoe(
      name: 'Jordan 1 Retro',
      color: 'Chicago',
      price: 189,
      image: 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=400',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _footDetected = true;
        });
        _scanController.stop();
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  /// v2.0 — resets the interactive placement (double-tap or button).
  void _resetPlacement() {
    setState(() {
      _shoeOffset = Offset.zero;
      _shoeScale = 1.0;
      _shoeRotation = 0.0;
    });
  }

  /// v2.0 gesture handlers — one ScaleGestureRecognizer drives everything:
  /// single finger drag moves the shoe, pinch zooms, twist rotates.
  void _onScaleStart(ScaleStartDetails details) {
    _gestureBaseScale = _shoeScale;
    _gestureBaseRotation = _shoeRotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _shoeScale = (_gestureBaseScale * details.scale).clamp(0.5, 2.5);
      _shoeRotation = _gestureBaseRotation + details.rotation;
      _shoeOffset = Offset(
        (_shoeOffset.dx + details.focalPointDelta.dx).clamp(-180.0, 180.0),
        (_shoeOffset.dy + details.focalPointDelta.dy).clamp(-320.0, 120.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraView(),
          _buildAROverlay(),
          _buildTopBar(),
          _buildShoeInfo(),
          _buildShoeSelector(),
          _buildControls(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simulated floor/ground
              Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAROverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Grid overlay
          CustomPaint(painter: ARGridPainter()),

          // Foot detection frame (visual guide)
          Center(
            child: Container(
              width: 220,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _footDetected ? AppTheme.success : AppTheme.accent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: _isScanning
                  ? AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: _scanController.value * 100,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.accent,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : null,
            ),
          ),

          // v2.0 — Interactive AR shoe layer: drag / pinch / twist / reset
          _buildShoeLayer(),

          // v2.0 — Gesture hint chip
          _buildGestureHint(),

          // Corner markers
          ..._buildCornerMarkers(),
        ],
      ),
    );
  }

  /// v2.0 — the freely placeable AR shoe with full gesture control.
  Widget _buildShoeLayer() {
    if (!_footDetected) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _resetPlacement,
        child: Center(
          child: Transform.translate(
            offset: _shoeOffset,
            child: Transform.rotate(
              angle: _shoeRotation,
              child: Transform.scale(
                scale: _shoeScale,
                child: Container(
                  width: 180,
                  height: 90,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_shoes[_selectedShoeIndex].image),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// v2.0 — floating hint + live zoom readout while the shoe is placed.
  Widget _buildGestureHint() {
    if (!_footDetected) return const SizedBox.shrink();
    return Positioned(
      top: 150,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: AppAnimations.medium,
          opacity: _footDetected ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, color: AppTheme.accent, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Drag · Pinch ×${_shoeScale.toStringAsFixed(1)} · Twist',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    final size = 40.0;
    final width = 3.0;
    final color = _footDetected ? AppTheme.success : AppTheme.accent;

    return [
      Positioned(
        top: 100,
        left: 40,
        child: SizedBox(width: size, height: size, child: Stack(children: [
          Container(width: size, height: width, color: color),
          Container(width: width, height: size, color: color),
        ])),
      ),
      Positioned(
        top: 100,
        right: 40,
        child: SizedBox(width: size, height: size, child: Stack(children: [
          Positioned(right: 0, child: Container(width: size, height: width, color: color)),
          Positioned(right: 0, child: Container(width: width, height: size, color: color)),
        ])),
      ),
      Positioned(
        bottom: 280,
        left: 40,
        child: SizedBox(width: size, height: size, child: Stack(children: [
          Positioned(bottom: 0, child: Container(width: size, height: width, color: color)),
          Container(width: width, height: size, color: color),
        ])),
      ),
      Positioned(
        bottom: 280,
        right: 40,
        child: SizedBox(width: size, height: size, child: Stack(children: [
          Positioned(bottom: 0, right: 0, child: Container(width: size, height: width, color: color)),
          Positioned(bottom: 0, right: 0, child: Container(width: width, height: size, color: color)),
        ])),
      ),
    ];
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
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_footDetected ? Icons.check_circle : Icons.radar,
                        color: _footDetected ? AppTheme.success : AppTheme.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _footDetected ? 'Foot Detected' : 'Scanning...',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => _showHelpDialog(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoeInfo() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: _footDetected
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        _shoes[_selectedShoeIndex].image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: AppTheme.surfaceLight);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shoes[_selectedShoeIndex].name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _shoes[_selectedShoeIndex].color,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '£${_shoes[_selectedShoeIndex].price}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildShoeSelector() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 200,
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _shoes.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedShoeIndex == index;
            return GestureDetector(
              onTap: () => setState(() {
              _selectedShoeIndex = index;
              _shoeOffset = Offset.zero;
              _shoeRotation = 0.0;
            }),
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                width: isSelected ? 80 : 64,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent.withOpacity(0.2) : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _shoes[index].image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.surfaceLight);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      bottom: 300,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.add,
            label: 'Zoom +',
            onTap: () => setState(() => _shoeScale = (_shoeScale + 0.1).clamp(0.5, 2.0)),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.remove,
            label: 'Zoom -',
            onTap: () => setState(() => _shoeScale = (_shoeScale - 0.1).clamp(0.5, 2.0)),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.rotate_left,
            label: 'Rotate',
            onTap: () => setState(() => _shoeRotation -= 0.2),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.flip,
            label: 'Flip',
            onTap: () => setState(() => _shoeRotation += 3.14),
          ),
          const SizedBox(height: 12),
          _buildControlButton(
            icon: Icons.restart_alt,
            label: 'Reset',
            onTap: _resetPlacement,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, color: AppTheme.accent),
                  label: const Text('Capture'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _footDetected ? () {} : null,
                  icon: const Icon(Icons.shopping_bag, color: AppTheme.background),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: AppTheme.surfaceLight,
                    disabledForegroundColor: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('How to use AR Try-On'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Point your camera at your feet'),
            SizedBox(height: 8),
            Text('2. Make sure your foot is within the frame'),
            SizedBox(height: 8),
            Text('3. Wait for foot detection'),
            SizedBox(height: 8),
            Text('4. Swipe to try different shoes'),
            SizedBox(height: 8),
            Text('5. Drag the shoe to reposition it'),
            SizedBox(height: 8),
            Text('6. Pinch with two fingers to zoom, twist to rotate'),
            SizedBox(height: 8),
            Text('7. Double-tap to reset the placement'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class ARShoe {
  final String name;
  final String color;
  final double price;
  final String image;

  ARShoe({
    required this.name,
    required this.color,
    required this.price,
    required this.image,
  });
}

class ARGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center crosshair
    final crossPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), crossPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
