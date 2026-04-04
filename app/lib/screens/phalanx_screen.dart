import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/ingestion_provider.dart';
import '../models/fuel_log.dart';

class PhalanxScreen extends StatefulWidget {
  const PhalanxScreen({super.key});

  @override
  State<PhalanxScreen> createState() => _PhalanxScreenState();
}

class _PhalanxScreenState extends State<PhalanxScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submitLog(IngestionProvider provider) {
    if (_controller.text.isNotEmpty) {
      final success = provider.logFuel(_controller.text);
      if (success) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("INGESTION LOGGED"),
            backgroundColor: LaconicTheme.spartanBronze,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("INVALID COMMAND"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingestionProvider = Provider.of<IngestionProvider>(context);
    final log = ingestionProvider.todayLog;

    return Scaffold(
      appBar: AppBar(title: const Text("P H A L A N X")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TACTICAL INGESTION",
              style: TextStyle(
                color: LaconicTheme.spartanBronze,
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildMacroSummary(log),
            const SizedBox(height: 30),
            const Text(
              "COMMAND INPUT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontFamily: "Courier"),
              decoration: InputDecoration(
                hintText: "e.g., 300g chicken or 2e",
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: LaconicTheme.ironGray.withValues(alpha: 0.1),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: LaconicTheme.spartanBronze),
                  onPressed: () => _submitLog(ingestionProvider),
                ),
              ),
              onSubmitted: (_) => _submitLog(ingestionProvider),
            ),
            const SizedBox(height: 30),
            const Text(
              "RECENT LOGS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (ingestionProvider.todayEntries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "NO LOGEntries DETECTED.",
                    style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.0),
                  ),
                ),
              ),
            ...ingestionProvider.todayEntries.map((entry) => _buildEntryTile(entry, ingestionProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSummary(FuelLog log) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.2),
        border: Border.all(color: LaconicTheme.spartanBronze.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _macroRow("PROTEIN", log.totalProtein, FuelLog.targetProtein, LaconicTheme.spartanBronze),
          const SizedBox(height: 12),
          _macroRow("CARBS", log.totalCarbs, FuelLog.targetCarbs, Colors.blueGrey),
          const SizedBox(height: 12),
          _macroRow("FAT", log.totalFat, FuelLog.targetFat, Colors.orangeAccent),
          const Divider(height: 32, color: LaconicTheme.ironGray),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL CALORIES", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                "${log.totalCalories} / ${FuelLog.targetCalories} kcal",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, double current, double target, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.0)),
            Text(
              "${current.toInt()}g / ${target.toInt()}g",
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (current / target).clamp(0.0, 1.0),
          backgroundColor: Colors.black,
          color: color,
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildEntryTile(dynamic entry, IngestionProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: LaconicTheme.ironGray.withValues(alpha: 0.1),
          border: Border.all(color: LaconicTheme.ironGray.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.itemName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  "${entry.calories} kcal | P: ${entry.protein.toInt()}g",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: () => provider.removeEntry(entry.id),
            ),
          ],
        ),
      ),
    );
  }
}
