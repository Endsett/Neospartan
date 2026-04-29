import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/analytics_metrics.dart';

/// Volume trend line chart
class VolumeTrendChart extends StatelessWidget {
  final List<TimeSeriesPoint> data;
  final String title;
  final Color lineColor;
  final bool showArea;
  final double height;

  const VolumeTrendChart({
    super.key,
    required this.data,
    this.title = 'Volume Trend',
    this.lineColor = LaconicTheme.spartanBronze,
    this.showArea = true,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY = data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
          ),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: LaconicTheme.ironGray.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (data.length / 5).ceil().toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = data[index].date;
                        return Text(
                          DateFormat('MM/dd').format(date),
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY,
              maxY: maxY * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: showArea
                      ? BarAreaData(
                          show: true,
                          color: lineColor.withValues(alpha: 0.1),
                        )
                      : BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => LaconicTheme.ironGray,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final point = data[index];
                      return LineTooltipItem(
                        '${DateFormat('MMM dd').format(point.date)}\n${point.value.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

/// Exercise progression chart
class ExerciseProgressionChart extends StatelessWidget {
  final ExerciseProgression progression;
  final double height;

  const ExerciseProgressionChart({
    super.key,
    required this.progression,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final data = progression.estimatedOneRM;
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final maxY = data.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              progression.exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (progression.personalRecord != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PR: ${progression.personalRecord!.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${progression.workoutsCount} sessions • ${progression.progressionRate > 0 ? '+' : ''}${progression.progressionRate.toStringAsFixed(1)}/week',
          style: TextStyle(
            color: progression.progressionRate > 0 ? Colors.green : Colors.orange,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: LaconicTheme.ironGray.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY * 1.1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: progression.isPlateauing ? Colors.orange : LaconicTheme.spartanBronze,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: progression.isPlateauing ? Colors.orange : LaconicTheme.spartanBronze,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: (progression.isPlateauing ? Colors.orange : LaconicTheme.spartanBronze)
                        .withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      child: const Center(child: Text('No data', style: TextStyle(color: Colors.grey))),
    );
  }
}

/// Weekly completion rate bar chart
class WeeklyCompletionChart extends StatelessWidget {
  final List<TimeSeriesPoint> weeklyRates;
  final double height;

  const WeeklyCompletionChart({
    super.key,
    required this.weeklyRates,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyRates.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: LaconicTheme.ironGray.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < weeklyRates.length) {
                    return Text(
                      DateFormat('MM/dd').format(weeklyRates[index].date),
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                        fontSize: 9,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 1.2,
          barGroups: weeklyRates.asMap().entries.map((e) {
            final index = e.key;
            final rate = e.value.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: rate,
                  color: rate >= 0.8
                      ? Colors.green
                      : rate >= 0.5
                          ? LaconicTheme.spartanBronze
                          : Colors.orange,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      child: const Center(child: Text('No data', style: TextStyle(color: Colors.grey))),
    );
  }
}

/// Exercise frequency pie chart
class ExerciseFrequencyChart extends StatelessWidget {
  final List<ExerciseFrequency> frequencies;
  final double height;
  final int maxItems;

  const ExerciseFrequencyChart({
    super.key,
    required this.frequencies,
    this.height = 200,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (frequencies.isEmpty) {
      return _buildEmptyState();
    }

    final displayItems = frequencies.take(maxItems).toList();
    final colors = [
      LaconicTheme.spartanBronze,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];

    final total = displayItems.fold<double>(0, (sum, f) => sum + f.frequency);

    return Row(
      children: [
        SizedBox(
          height: height,
          width: height,
          child: PieChart(
            PieChartData(
              sections: displayItems.asMap().entries.map((e) {
                final index = e.key;
                final freq = e.value;
                final percent = total > 0 ? (freq.frequency / total * 100) : 0;

                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: freq.frequency.toDouble(),
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displayItems.asMap().entries.map((e) {
              final index = e.key;
              final freq = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        freq.exerciseName,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${freq.frequency}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      child: const Center(child: Text('No data', style: TextStyle(color: Colors.grey))),
    );
  }
}

/// Streak counter widget
class StreakCounter extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final double size;

  const StreakCounter({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LaconicTheme.spartanBronze,
                LaconicTheme.spartanBronze.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: size * 0.3,
                ),
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentStreak == 1 ? 'DAY STREAK' : 'DAY STREAK',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        if (longestStreak > currentStreak)
          Text(
            'Best: $longestStreak',
            style: TextStyle(
              color: LaconicTheme.spartanBronze.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

/// Period comparison card
class PeriodComparisonCard extends StatelessWidget {
  final PeriodComparison comparison;

  const PeriodComparisonCard({
    super.key,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VS LAST PERIOD',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildComparisonItem('Volume', comparison.volumeChangePercent)),
            Expanded(child: _buildComparisonItem('Workouts', comparison.workoutChangePercent)),
            Expanded(child: _buildComparisonItem('Duration', comparison.durationChangePercent)),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonItem(String label, double changePercent) {
    final isPositive = changePercent > 0;
    final isNeutral = changePercent == 0;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNeutral
                  ? Icons.remove
                  : isPositive
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
              color: isNeutral
                  ? Colors.grey
                  : isPositive
                      ? Colors.green
                      : Colors.red,
              size: 14,
            ),
            Text(
              '${changePercent.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: isNeutral
                    ? Colors.grey
                    : isPositive
                        ? Colors.green
                        : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
