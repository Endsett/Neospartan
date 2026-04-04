import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../theme.dart';

class StadionScreen extends StatelessWidget {
  const StadionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("S T A D I O N")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "COMBAT CONDITIONING",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _exerciseCard(
            context,
            "PLIO SPARTAN BURPEE",
            "Explosive power development via triple extension.",
            "L61p2B9M2wo", // Example YouTube ID
          ),
          _exerciseCard(
            context,
            "IRON ISO SHADOWBOX",
            "Isometric shoulder endurance for metabolic conditioning.",
            "WpYm78WJ2U0", // Example YouTube ID
          ),
          _exerciseCard(
            context,
            "STADION SPRINTS",
            "Alactic burst training for elite combat recovery.",
            "6_0q8T8X0mI", // Example YouTube ID
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, String title, String description, String videoId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: LaconicTheme.ironGray.withValues(alpha: 0.3),
        border: Border(left: BorderSide(color: LaconicTheme.spartanBronze, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LaconicTheme.spartanBronze,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          YouTubePreview(videoId: videoId),
        ],
      ),
    );
  }
}

class YouTubePreview extends StatefulWidget {
  final String videoId;
  const YouTubePreview({super.key, required this.videoId});

  @override
  State<YouTubePreview> createState() => _YouTubePreviewState();
}

class _YouTubePreviewState extends State<YouTubePreview> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: LaconicTheme.spartanBronze,
      progressColors: const ProgressBarColors(
        playedColor: LaconicTheme.spartanBronze,
        handleColor: Colors.amber,
      ),
    );
  }

}
