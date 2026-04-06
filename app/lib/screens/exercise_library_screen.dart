import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_state.dart';

/// Exercise Library Screen - Browse and search exercises
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
      backgroundColor: LaconicTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: LaconicTheme.ironGray,
        title: const Text(
          'EXERCISE LIBRARY',
          style: TextStyle(
            color: LaconicTheme.boneWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
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
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: LaconicTheme.boneWhite),
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: TextStyle(color: LaconicTheme.mistGray),
          prefixIcon: const Icon(Icons.search, color: LaconicTheme.warmGold),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: LaconicTheme.mistGray),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ExerciseProvider>().search('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
                    labelStyle: TextStyle(
                      color: isSelected
                          ? LaconicTheme.deepBlack
                          : LaconicTheme.boneWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: LaconicTheme.ironGray,
                    selectedColor: LaconicTheme.spartanBronze,
                    side: BorderSide(
                      color: isSelected
                          ? LaconicTheme.spartanBronze
                          : LaconicTheme.boneWhite.withValues(alpha: 0.3),
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
                    color: isSelected ? LaconicTheme.deepBlack : color,
                    size: 18,
                  ),
                  label: Text(provider.getCategoryName(category)),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? LaconicTheme.deepBlack
                        : LaconicTheme.boneWhite,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: LaconicTheme.ironGray,
                  selectedColor: color,
                  side: BorderSide(
                    color: isSelected
                        ? color
                        : LaconicTheme.boneWhite.withValues(alpha: 0.3),
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
      backgroundColor: LaconicTheme.ironGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
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
                          style: TextStyle(
                            color: LaconicTheme.boneWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.getCategoryName(exercise.category),
                          style: TextStyle(
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
                  color: LaconicTheme.spartanBronze.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LaconicTheme.spartanBronze.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: LaconicTheme.spartanBronze,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.targetMetaphor,
                        style: const TextStyle(
                          color: LaconicTheme.spartanBronze,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Instructions
              const Text(
                'INSTRUCTIONS',
                style: TextStyle(
                  color: LaconicTheme.boneWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions,
                style: TextStyle(
                  color: LaconicTheme.boneWhite.withValues(alpha: 0.8),
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
                    Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _buildDetailChip(
                    'Level',
                    '${exercise.minFitnessLevel.name}-${exercise.maxFitnessLevel.name}',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Muscles
              if (exercise.primaryMuscles.isNotEmpty) ...[
                const Text(
                  'MUSCLES',
                  style: TextStyle(
                    color: LaconicTheme.boneWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
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
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: LaconicTheme.deepBlack,
                      side: BorderSide(
                        color: LaconicTheme.boneWhite.withValues(alpha: 0.3),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaconicTheme.spartanBronze,
                    foregroundColor: LaconicTheme.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: LaconicTheme.boneWhite,
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
          color: LaconicTheme.ironGray,
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
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
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
                      style: const TextStyle(
                        color: LaconicTheme.boneWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.targetMetaphor,
                      style: TextStyle(
                        color: LaconicTheme.boneWhite.withValues(alpha: 0.5),
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
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.getIntensityStars(exercise.intensityLevel),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
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
                          decoration: BoxDecoration(
                            color: LaconicTheme.deepBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            muscle.toUpperCase(),
                            style: TextStyle(
                              color: LaconicTheme.boneWhite.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 8,
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
