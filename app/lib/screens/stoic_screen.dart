import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../repositories/stoic_repository.dart';
import '../models/stoic_quote.dart';
import '../providers/auth_provider.dart';

/// The Mind - Stoic Tracking Screen
class StoicScreen extends StatefulWidget {
  const StoicScreen({super.key});

  @override
  State<StoicScreen> createState() => _StoicScreenState();
}

class _StoicScreenState extends State<StoicScreen> {
  final StoicRepository _stoicRepo = StoicRepository();
  
  double _flowStateValue = 8;
  List<StoicEntry> _flowHistory = [];
  bool _isLoading = true;
  String? _userId;
  
  double _avgFlow = 0;
  int _mentalStamina = 0;
  int _distractionCount = 0;
  
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userId = authProvider.userId;
    
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entries = await _stoicRepo.getEntriesForRange(
        _userId!,
        DateTime.now().subtract(const Duration(days: 30)),
        DateTime.now(),
      );

      _flowHistory = entries.where((e) => e.entryType == StoicEntryType.flowLog).toList();
      _calculateStats();

      if (_flowHistory.isNotEmpty) {
        final latest = _flowHistory.first;
        _flowStateValue = (latest.flowStateValue ?? 7).toDouble();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading stoic data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    if (_flowHistory.isEmpty) {
      _avgFlow = 7.0;
      _mentalStamina = 70;
      _distractionCount = 5;
      return;
    }

    final flowValues = _flowHistory
        .where((e) => e.flowStateValue != null)
        .map((e) => e.flowStateValue!.toDouble())
        .toList();
    
    if (flowValues.isNotEmpty) {
      _avgFlow = flowValues.reduce((a, b) => a + b) / flowValues.length;
    }

    final recentWeek = _flowHistory.where(
      (e) => e.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))),
    ).length;
    _mentalStamina = (recentWeek * 10).clamp(50, 100);

    final highFlowDays = _flowHistory.where((e) => (e.flowStateValue ?? 0) >= 7).length;
    _distractionCount = (_flowHistory.length - highFlowDays).clamp(0, 10);
  }

  void _onFlowStateChanged(double value) {
    setState(() => _flowStateValue = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _saveFlowState(value);
    });
  }

  Future<void> _saveFlowState(double value) async {
    if (_userId == null) return;

    try {
      final entry = StoicEntry(
        userId: _userId!,
        entryType: StoicEntryType.flowLog,
        flowStateValue: value.round(),
        sessionDate: DateTime.now(),
      );

      await _stoicRepo.saveEntry(entry);
    } catch (e) {
      debugPrint('Error saving flow state: $e');
    }
  }

  Future<void> _showDailyReflectionDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DailyReflectionDialog(),
    );

    if (result != null && _userId != null) {
      try {
        final entry = StoicEntry(
          userId: _userId!,
          entryType: StoicEntryType.reflection,
          reflectionText: result['reflection'] as String?,
          quoteId: result['quote_id'] as String?,
          quoteAuthor: result['quote_author'] as String?,
          quoteText: result['quote_text'] as String?,
          sessionDate: DateTime.now(),
        );

        await _stoicRepo.saveEntry(entry);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reflection saved'),
              backgroundColor: LaconicTheme.secondary,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving reflection: $e');
      }
    }
  }

  void _showPhilosopherQuotes(String philosopher) {
    final quotes = StoicQuote.library.where((q) => 
      q.author.toLowerCase().contains(philosopher.toLowerCase())
    ).toList();

    if (quotes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: LaconicTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                philosopher.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: LaconicTheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: quotes.length.clamp(0, 5),
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: LaconicTheme.surfaceContainer,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${quote.text.substring(0, quote.text.length > 40 ? 40 : quote.text.length)}..."',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: LaconicTheme.onSurface,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '— ${quote.author}',
                            style: GoogleFonts.workSans(
                              fontSize: 12,
                              color: LaconicTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LaconicTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: LaconicTheme.secondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.psychology, color: LaconicTheme.secondary),
            const SizedBox(width: 12),
            Text(
              'THE MIND',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.02,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: LaconicTheme.secondary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stoic Analytics',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.secondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mental',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.onSurface,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            Text(
              'Resilience',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: -0.04,
                height: 1,
              ),
            ),
            const SizedBox(height: 32),
            _buildFocusAnalyticsSection(),
            const SizedBox(height: 32),
            _buildFlowStateSection(),
            const SizedBox(height: 32),
            _buildPhilosophicalDatabaseSection(),
            const SizedBox(height: 32),
            _buildMementoMoriCTA(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Focus Analytics',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LaconicTheme.onSurface,
              ),
            ),
            Row(
              children: [
                Container(width: 12, height: 12, color: LaconicTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Flow State',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    color: LaconicTheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: LaconicTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Power Output',
                  style: GoogleFonts.workSans(
                    fontSize: 10,
                    color: LaconicTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: DynamicFocusChartPainter(
              flowData: _flowHistory
                  .where((e) => e.flowStateValue != null)
                  .map((e) => (e.flowStateValue!.toDouble() / 10).clamp(0.0, 1.0))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Avg Flow',
                value: _avgFlow.toStringAsFixed(1),
                trend: '+0.2',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Mental Stamina',
                value: '$_mentalStamina%',
                trend: '+3%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Distractions',
                value: '$_distractionCount',
                trend: '-1',
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainerLow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 10,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: LaconicTheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trend,
                style: GoogleFonts.workSans(
                  fontSize: 10,
                  color: isPositive
                      ? LaconicTheme.secondary
                      : LaconicTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Flow State',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: LaconicTheme.surfaceContainerLow,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DISTRACTED',
                    style: GoogleFonts.workSans(
                      fontSize: 10,
                      color: LaconicTheme.onSurfaceVariant,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    'IN THE ZONE',
                    style: GoogleFonts.workSans(
                      fontSize: 10,
                      color: LaconicTheme.secondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: LaconicTheme.secondary,
                  inactiveTrackColor: LaconicTheme.surfaceContainerHighest,
                  thumbColor: LaconicTheme.secondary,
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 0,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _flowStateValue,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: _onFlowStateChanged,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: LaconicTheme.secondary,
                    ),
                    child: Text(
                      '${_flowStateValue.toInt()} / 10',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LaconicTheme.onSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _flowStateValue >= 7
                        ? 'Deep Flow'
                        : _flowStateValue >= 4
                        ? 'Focused'
                        : 'Scattered',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      color: LaconicTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhilosophicalDatabaseSection() {
    final philosophers = [
      {'name': 'Marcus Aurelius', 'title': 'Meditations'},
      {'name': 'Seneca', 'title': 'Letters'},
      {'name': 'Epictetus', 'title': 'Discourses'},
      {'name': 'Musonius Rufus', 'title': 'Lectures'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Philosophical Database',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: philosophers.map((philosopher) {
            return GestureDetector(
              onTap: () => _showPhilosopherQuotes(philosopher['name']!),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainerLow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      philosopher['name']!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      philosopher['title']!,
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        color: LaconicTheme.secondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMementoMoriCTA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LaconicTheme.surfaceContainerLow,
        border: Border.all(color: LaconicTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_empty,
                color: LaconicTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'MEMENTO MORI',
                style: GoogleFonts.workSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LaconicTheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"You could leave life right now. Let that determine what you do and say and think."',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: LaconicTheme.onSurface,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— Marcus Aurelius, Meditations',
            style: GoogleFonts.workSans(
              fontSize: 12,
              color: LaconicTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDailyReflectionDialog,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(
                'DAILY REFLECTION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: LaconicTheme.onSurface,
                backgroundColor: LaconicTheme.surfaceBright,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: LaconicTheme.outlineVariant),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic focus chart painter
class DynamicFocusChartPainter extends CustomPainter {
  final List<double> flowData;

  DynamicFocusChartPainter({required this.flowData});

  @override
  void paint(Canvas canvas, Size size) {
    if (flowData.isEmpty) {
      _drawDefaultChart(canvas, size);
      return;
    }

    final flowPaint = Paint()
      ..color = LaconicTheme.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final points = _calculatePoints(flowData, size);
    
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, flowPaint);

      final pointPaint = Paint()
        ..color = LaconicTheme.secondary
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }

    final powerPaint = Paint()
      ..color = LaconicTheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final powerPoints = _calculatePowerPoints(flowData, size);
    
    if (powerPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(powerPoints.first.dx, powerPoints.first.dy);
      for (int i = 1; i < powerPoints.length; i++) {
        path.lineTo(powerPoints[i].dx, powerPoints[i].dy);
      }
      canvas.drawPath(path, powerPaint);
    }
  }

  List<Offset> _calculatePoints(List<double> data, Size size) {
    final points = <Offset>[];
    final stepX = size.width / (data.length > 1 ? data.length - 1 : 1);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - data[i].clamp(0.0, 1.0));
      points.add(Offset(x, y));
    }
    
    return points;
  }

  List<Offset> _calculatePowerPoints(List<double> data, Size size) {
    final powerData = data.map((f) => (1.2 - f).clamp(0.3, 1.0)).toList();
    return _calculatePoints(powerData, size);
  }

  void _drawDefaultChart(Canvas canvas, Size size) {
    final flowPaint = Paint()
      ..color = LaconicTheme.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.2);
    canvas.drawPath(path, flowPaint);

    final powerPaint = Paint()
      ..color = LaconicTheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final powerPath = Path();
    powerPath.moveTo(0, size.height * 0.8);
    powerPath.lineTo(size.width * 0.2, size.height * 0.6);
    powerPath.lineTo(size.width * 0.4, size.height * 0.5);
    powerPath.lineTo(size.width * 0.6, size.height * 0.6);
    powerPath.lineTo(size.width * 0.8, size.height * 0.4);
    powerPath.lineTo(size.width, size.height * 0.5);
    canvas.drawPath(powerPath, powerPaint);

    final pointPaint = Paint()
      ..color = LaconicTheme.secondary
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DynamicFocusChartPainter oldDelegate) {
    return oldDelegate.flowData.length != flowData.length;
  }
}

/// Daily Reflection Dialog
class DailyReflectionDialog extends StatefulWidget {
  const DailyReflectionDialog({super.key});

  @override
  State<DailyReflectionDialog> createState() => _DailyReflectionDialogState();
}

class _DailyReflectionDialogState extends State<DailyReflectionDialog> {
  final _controller = TextEditingController();
  StoicQuote? _selectedQuote;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LaconicTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DAILY REFLECTION',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: LaconicTheme.secondary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your reflection here...',
                hintStyle: GoogleFonts.inter(color: LaconicTheme.outline),
                filled: true,
                fillColor: LaconicTheme.surfaceContainer,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: LaconicTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a quote:',
              style: GoogleFonts.workSans(
                fontSize: 12,
                color: LaconicTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: StoicQuote.library.take(5).length,
                itemBuilder: (context, index) {
                  final quote = StoicQuote.library[index];
                  final isSelected = _selectedQuote?.text == quote.text;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedQuote = quote),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? LaconicTheme.secondary.withValues(alpha: 0.2)
                            : LaconicTheme.surfaceContainer,
                        border: Border.all(
                          color: isSelected
                              ? LaconicTheme.secondary
                              : LaconicTheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${quote.text.substring(0, quote.text.length > 40 ? 40 : quote.text.length)}..."',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: LaconicTheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            '— ${quote.author}',
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              color: LaconicTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.spaceGrotesk(
                      color: LaconicTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'reflection': _controller.text,
                      'quote_id': _selectedQuote != null
                          ? StoicQuote.library.indexOf(_selectedQuote!).toString()
                          : null,
                      'quote_author': _selectedQuote?.author,
                      'quote_text': _selectedQuote?.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaconicTheme.secondary,
                    foregroundColor: LaconicTheme.onSecondary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
