import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../theme.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_state.dart';

/// Exercise Library Screen - Browse and search exercises
/// Blood & Bronze themed armory of exercises
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      appBar: AppBar(
        backgroundColor: LaconicTheme.surfaceContainerLow,
        title: Text(
          'EXERCISE LIBRARY',
          style: GoogleFonts.spaceGrotesk(
            color: LaconicTheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          // Category filters
          _buildCategoryChips(),
          // Exercise grid
          Expanded(
            child: Consumer<ExerciseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                if (provider.error != null) {
                  return _buildErrorState(provider.error!);
                }

                if (provider.filteredExercises.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildExerciseGrid(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: LaconicTheme.surfaceContainer),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: LaconicTheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: GoogleFonts.inter(color: LaconicTheme.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search, color: LaconicTheme.secondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: LaconicTheme.outline),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ExerciseProvider>().search('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          context.read<ExerciseProvider>().search(value);
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<ExerciseProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length + 1,
            itemBuilder: (context, index) {
              // All filter
              if (index == 0) {
                final isSelected = provider.selectedCategory == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: const Text('ALL'),
                    labelStyle: GoogleFonts.workSans(
                      color: isSelected
                          ? LaconicTheme.onSecondary
                          : LaconicTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    backgroundColor: LaconicTheme.surfaceContainer,
                    selectedColor: LaconicTheme.secondary,
                    side: BorderSide(
                      color: isSelected
                          ? LaconicTheme.secondary
                          : LaconicTheme.outlineVariant,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    onSelected: (_) {
                      provider.filterByCategory(null);
                    },
                  ),
                );
              }

              final category = provider.categories[index - 1];
              final isSelected = provider.selectedCategory == category;
              final color = provider.getCategoryColor(category);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  avatar: Icon(
                    provider.getCategoryIcon(category),
                    color: isSelected ? LaconicTheme.onSecondary : color,
                    size: 18,
                  ),
                  label: Text(provider.getCategoryName(category)),
                  labelStyle: GoogleFonts.workSans(
                    color: isSelected
                        ? LaconicTheme.onSecondary
                        : LaconicTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  backgroundColor: LaconicTheme.surfaceContainer,
                  selectedColor: color,
                  side: BorderSide(
                    color: isSelected ? color : LaconicTheme.outlineVariant,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  onSelected: (_) {
                    provider.filterByCategory(isSelected ? null : category);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExerciseGrid(ExerciseProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = provider.filteredExercises[index];
        return _ExerciseCard(
          exercise: exercise,
          onTap: () => _showExerciseDetail(context, exercise),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const CardSkeleton(lines: 2);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorState(
      message: 'Failed to load exercises',
      retryLabel: 'RETRY',
      onRetry: () {
        context.read<ExerciseProvider>().loadExercises();
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      title: 'No exercises found',
      subtitle: 'Try adjusting your search or filters',
      icon: Icons.fitness_center,
      actionLabel: 'CLEAR FILTERS',
      onAction: () {
        context.read<ExerciseProvider>().clearFilters();
        _searchController.clear();
      },
    );
  }

  void _showExerciseDetail(BuildContext context, Exercise exercise) {
    final provider = context.read<ExerciseProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: LaconicTheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.zero),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider
                          .getCategoryColor(exercise.category)
                          .withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      provider.getCategoryIcon(exercise.category),
                      color: provider.getCategoryColor(exercise.category),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: LaconicTheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.getCategoryName(exercise.category),
                          style: GoogleFonts.inter(
                            color: provider.getCategoryColor(exercise.category),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Metaphor
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LaconicTheme.secondary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: LaconicTheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: LaconicTheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.targetMetaphor,
                        style: GoogleFonts.inter(
                          color: LaconicTheme.secondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Instructions
              Text(
                'INSTRUCTIONS',
                style: GoogleFonts.spaceGrotesk(
                  color: LaconicTheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions,
                style: GoogleFonts.inter(
                  color: LaconicTheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Details
              Row(
                children: [
                  _buildDetailChip(
                    'Intensity',
                    provider.getIntensityStars(exercise.intensityLevel),
                    LaconicTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildDetailChip(
                    'Level',
                    '${exercise.minFitnessLevel.name}-${exercise.maxFitnessLevel.name}',
                    LaconicTheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Muscles
              if (exercise.primaryMuscles.isNotEmpty) ...[
                Text(
                  'MUSCLES',
                  style: GoogleFonts.spaceGrotesk(
                    color: LaconicTheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: exercise.primaryMuscles.map((muscle) {
                    return Chip(
                      label: Text(
                        muscle.toUpperCase(),
                        style: GoogleFonts.workSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: LaconicTheme.onSurface,
                        ),
                      ),
                      backgroundColor: LaconicTheme.surfaceContainer,
                      side: const BorderSide(
                        color: LaconicTheme.outlineVariant,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaconicTheme.secondary,
                    foregroundColor: LaconicTheme.onSecondary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.workSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: LaconicTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Exercise Card Widget
class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExerciseProvider>();
    final categoryColor = provider.getCategoryColor(exercise.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LaconicTheme.surfaceContainer,
          border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: categoryColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.getCategoryIcon(exercise.category),
                    color: categoryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.getCategoryName(exercise.category).toUpperCase(),
                    style: GoogleFonts.workSans(
                      color: categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: GoogleFonts.spaceGrotesk(
                        color: LaconicTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.targetMetaphor,
                      style: GoogleFonts.inter(
                        color: LaconicTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Intensity
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: LaconicTheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.getIntensityStars(exercise.intensityLevel),
                          style: GoogleFonts.inter(
                            color: LaconicTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Muscle chips
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: exercise.primaryMuscles.take(3).map((muscle) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: LaconicTheme.surfaceContainerHigh,
                          ),
                          child: Text(
                            muscle.toUpperCase(),
                            style: GoogleFonts.workSans(
                              color: LaconicTheme.onSurfaceVariant,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
