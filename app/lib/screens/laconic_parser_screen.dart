import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Laconic Parser Screen - OCR Verification
/// Based on the_laconic_parser_verification design
class LaconicParserScreen extends StatelessWidget {
  final VoidCallback? onConfirm;

  const LaconicParserScreen({super.key, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.background,
        elevation: 0,
        leading: const Icon(Icons.menu, color: LaconicTheme.primary),
        title: Text(
          'THE SOVEREIGN ATHLETE',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LaconicTheme.primary,
            letterSpacing: -0.02,
          ),
        ),
        actions: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: LaconicTheme.surfaceContainerHigh,
              border: Border.all(color: LaconicTheme.outlineVariant),
            ),
            child: const Icon(
              Icons.person,
              color: LaconicTheme.primary,
              size: 16,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: LaconicTheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE LACONIC PARSER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: LaconicTheme.onSurface,
                    letterSpacing: -0.04,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 32,
                      color: LaconicTheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VERIFY TACTICAL INPUT',
                      style: GoogleFonts.workSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.secondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Split Screen
          Expanded(
            child: Row(
              children: [
                // Left: Raw Image
                Expanded(
                  child: Container(
                    color: LaconicTheme.surfaceContainerLow,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Placeholder for scanned image
                        Container(
                          color: LaconicTheme.surfaceContainer,
                          child: Icon(
                            Icons.document_scanner,
                            color: LaconicTheme.outlineVariant,
                            size: 64,
                          ),
                        ),
                        // Scanning overlay effect
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: LaconicTheme.surfaceContainerHigh
                                  .withValues(alpha: 0.8),
                              border: const Border(
                                left: BorderSide(
                                  color: LaconicTheme.secondary,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.camera_enhance,
                                  color: LaconicTheme.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'RAW_SOURCE_03B',
                                  style: GoogleFonts.workSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: LaconicTheme.onSurface,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Parsed Table
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: LaconicTheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: LaconicTheme.surfaceContainerLow,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Text(
                                  'Exercise',
                                  style: GoogleFonts.workSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: LaconicTheme.onSurfaceVariant,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Weight',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.workSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: LaconicTheme.onSurfaceVariant,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Reps',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.workSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: LaconicTheme.onSurfaceVariant,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Parsed Rows
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _buildParsedRow(
                                'ZERCHER SQUAT',
                                '140',
                                'KG',
                                '5',
                                '98%',
                                false,
                              ),
                              _buildParsedRow(
                                'SANDBAG CARRY',
                                '80',
                                'KG',
                                '40m',
                                '92%',
                                false,
                              ),
                              _buildParsedRow(
                                'REAR DELT FLY',
                                '12',
                                'KG',
                                '15',
                                '64%',
                                true,
                              ),
                              _buildParsedRow(
                                'STRICTURE PRESS',
                                '60',
                                'KG',
                                '8',
                                '99%',
                                false,
                              ),
                            ],
                          ),
                        ),

                        // Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: LaconicTheme.surfaceContainerLow,
                            border: Border(
                              top: BorderSide(
                                color: LaconicTheme.surfaceContainerHigh,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: LaconicTheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Verification Status: Pending',
                                    style: GoogleFonts.workSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: LaconicTheme.onSurface,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '4/4 Captured',
                                style: GoogleFonts.workSans(
                                  fontSize: 10,
                                  color: LaconicTheme.onSurfaceVariant,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80, right: 24),
        child: ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.keyboard_double_arrow_right),
          label: Text(
            'CONFIRM DATA',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: LaconicTheme.secondary,
            foregroundColor: LaconicTheme.onSecondary,
            elevation: 8,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            shadowColor: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildParsedRow(
    String exercise,
    String weight,
    String unit,
    String reps,
    String confidence,
    bool hasWarning,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: LaconicTheme.surfaceContainerLow),
        ),
        color: hasWarning ? LaconicTheme.primary.withValues(alpha: 0.05) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      exercise,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: LaconicTheme.onSurface,
                      ),
                    ),
                    if (hasWarning) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.warning,
                        color: LaconicTheme.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasWarning
                      ? 'Review required: $confidence CONFIDENCE'
                      : 'Confidence: $confidence',
                  style: GoogleFonts.workSans(
                    fontSize: 9,
                    fontWeight: hasWarning ? FontWeight.w700 : FontWeight.w500,
                    color: hasWarning
                        ? LaconicTheme.primary
                        : LaconicTheme.secondary.withValues(alpha: 0.6),
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: hasWarning
                      ? LaconicTheme.primary.withValues(alpha: 0.2)
                      : LaconicTheme.surfaceContainerHighest,
                  border: hasWarning
                      ? Border.all(
                          color: LaconicTheme.primary.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Text(
                  '$weight $unit',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: hasWarning
                        ? LaconicTheme.primary
                        : LaconicTheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: LaconicTheme.surfaceContainerHighest,
                ),
                child: Text(
                  reps,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: LaconicTheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
