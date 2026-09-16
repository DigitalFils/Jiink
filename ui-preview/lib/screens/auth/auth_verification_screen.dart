import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AuthVerificationScreen extends StatefulWidget {
  const AuthVerificationScreen({super.key});

  @override
  State<AuthVerificationScreen> createState() => _AuthVerificationScreenState();
}

class _AuthVerificationScreenState extends State<AuthVerificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;
  bool _isVerifying = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isVerified = true;
          _controller.stop();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildScanArea(),
              const SizedBox(height: 24),
              if (_isVerified) ...[
                _buildVerificationResult(),
                const SizedBox(height: 24),
                _buildCertificateDetails(),
                const SizedBox(height: 24),
                _buildSecurityFeatures(),
                const SizedBox(height: 24),
                _buildGuarantee(),
              ] else ...[
                _buildVerificationSteps(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        const Text(
          'Dewu Authentication',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildScanArea() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isVerified ? AppTheme.success : AppTheme.accent.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circuit board background pattern
          CustomPaint(painter: CircuitPainter(), size: const Size(double.infinity, double.infinity)),

          // Product image
          Container(
            width: 200,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image, color: AppTheme.textMuted, size: 48));
                },
              ),
            ),
          ),

          // Scanning line
          if (_isVerifying)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 40 + _scanAnimation.value * 240,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.accent,
                          AppTheme.accent,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Corner markers
          ..._buildCornerMarkers(),

          // Verified badge
          if (_isVerified)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
            ),

          // Status text
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isVerified ? AppTheme.success.withOpacity(0.2) : AppTheme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isVerifying)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accent,
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isVerifying ? 'Analyzing product details...' : 'Authentication PASSED',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isVerified ? AppTheme.success : AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const markerSize = 30.0;
    const markerWidth = 3.0;
    final color = _isVerified ? AppTheme.success : AppTheme.accent;

    return [
      // Top-left
      Positioned(
        top: 16,
        left: 16,
        child: SizedBox(
          width: markerSize,
          height: markerSize,
          child: Stack(
            children: [
              Container(width: markerSize, height: markerWidth, color: color),
              Container(width: markerWidth, height: markerSize, color: color),
            ],
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 16,
        right: 16,
        child: SizedBox(
          width: markerSize,
          height: markerSize,
          child: Stack(
            children: [
              Positioned(right: 0, child: Container(width: markerSize, height: markerWidth, color: color)),
              Positioned(right: 0, child: Container(width: markerWidth, height: markerSize, color: color)),
            ],
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 16,
        left: 16,
        child: SizedBox(
          width: markerSize,
          height: markerSize,
          child: Stack(
            children: [
              Positioned(bottom: 0, child: Container(width: markerSize, height: markerWidth, color: color)),
              Container(width: markerWidth, height: markerSize, color: color),
            ],
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 16,
        right: 16,
        child: SizedBox(
          width: markerSize,
          height: markerSize,
          child: Stack(
            children: [
              Positioned(bottom: 0, right: 0, child: Container(width: markerSize, height: markerWidth, color: color)),
              Positioned(bottom: 0, right: 0, child: Container(width: markerWidth, height: markerSize, color: color)),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildVerificationSteps() {
    final steps = [
      VerificationStep(title: 'Visual Inspection', description: 'Checking materials, stitching, logos', isComplete: true),
      VerificationStep(title: 'Label Analysis', description: 'Verifying tags, serial numbers', isComplete: true),
      VerificationStep(title: 'Material Testing', description: 'Analyzing fabric composition', isComplete: false, isActive: true),
      VerificationStep(title: 'Expert Review', description: 'Final authentication decision', isComplete: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Process',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.isComplete ? AppTheme.success : (step.isActive ? AppTheme.accent : AppTheme.surface),
                    shape: BoxShape.circle,
                    border: step.isActive ? Border.all(color: AppTheme.accent, width: 2) : null,
                  ),
                  child: Center(
                    child: step.isComplete
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : (step.isActive
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background))
                            : Text(
                                '${entry.key + 1}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                              )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: step.isComplete || step.isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVerificationResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.success.withOpacity(0.2), AppTheme.success.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: AppTheme.success, size: 48),
          const SizedBox(height: 12),
          const Text(
            '正品认证 PASS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.success,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '鉴定通过 • 真伪无忧',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge, color: AppTheme.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Certificate Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          _buildDetailRow('商品', 'Nike Air Dunk Low'),
          _buildDetailRow('鉴定编号', 'DP20251028-77291'),
          _buildDetailRow('鉴定时间', '2025-10-28 14:32:17'),
          _buildDetailRow('鉴定师', 'POIZON 鉴定团队 • 专家A07'),
          _buildDetailRow('鉴定结论', '正品 / Authentic'),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility, color: AppTheme.background),
              label: const Text('查看鉴定证书详情'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatures() {
    final features = [
      SecurityFeature(icon: Icons.qr_code_scanner, title: 'QR Code Verification', desc: 'Scan to verify authenticity'),
      SecurityFeature(icon: Icons.enhanced_encryption, title: 'Blockchain Record', desc: 'Immutable certificate on chain'),
      SecurityFeature(icon: Icons.history, title: 'Full Provenance', desc: 'Complete ownership history'),
      SecurityFeature(icon: Icons.shield, title: 'Multi-point Check', desc: '20+ inspection points verified'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Features',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(feature.icon, color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.desc,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGuarantee() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.workspace_premium, color: AppTheme.gold, size: 32),
          SizedBox(height: 8),
          Text(
            '100%正品保障 • 假一赔十',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.gold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'If proven counterfeit, receive 10x refund',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationStep {
  final String title;
  final String description;
  final bool isComplete;
  final bool isActive;

  VerificationStep({
    required this.title,
    required this.description,
    this.isComplete = false,
    this.isActive = false,
  });
}

class SecurityFeature {
  final IconData icon;
  final String title;
  final String desc;

  SecurityFeature({required this.icon, required this.title, required this.desc});
}

class CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw circuit-like lines
    for (var i = 0; i < 15; i++) {
      final startX = (i * 37.0) % size.width;
      final startY = (i * 53.0) % size.height;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + 80, startY),
        paint,
      );
      canvas.drawLine(
        Offset(startX + 80, startY),
        Offset(startX + 80, startY + 40),
        paint,
      );
    }

    // Draw nodes
    final nodePaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final x = (i * 67.0 + 30) % size.width;
      final y = (i * 97.0 + 50) % size.height;
      canvas.drawCircle(Offset(x, y), 4, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
