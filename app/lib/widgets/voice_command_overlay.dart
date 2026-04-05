import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme.dart';

class VoiceCommandOverlay extends StatefulWidget {
  final Function(String command) onCommand;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const VoiceCommandOverlay({
    super.key,
    required this.onCommand,
    this.isVisible = false,
    this.onToggleVisibility,
  });

  @override
  State<VoiceCommandOverlay> createState() => _VoiceCommandOverlayState();
}

class _VoiceCommandOverlayState extends State<VoiceCommandOverlay>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidenceLevel = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
  }

  void _initializeSpeech() async {
    _speech = stt.SpeechToText();

    bool available = await _speech.initialize(
      onError: (val) {
        setState(() {
          _isListening = false;
        });
        _showErrorSnackbar('Speech recognition error: ${val.errorMsg}');
      },
      onStatus: (val) {
        setState(() {
          _isListening = val == 'listening';
        });

        if (_isListening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );

    if (available) {
      setState(() {
        _speechEnabled = true;
      });
    }
  }

  void _startListening() {
    if (!_speechEnabled) return;

    _speech.listen(
      onResult: (val) => setState(() {
        _lastWords = val.recognizedWords;
        if (val.hasConfidenceRating && val.confidence > 0) {
          _confidenceLevel = val.confidence;
        }

        // Process command if confidence is high enough
        if (_confidenceLevel > 0.7 && _lastWords.isNotEmpty) {
          _processCommand(_lastWords);
        }
      }),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Voice command patterns
    if (lowerCommand.contains('next set') || lowerCommand.contains('next')) {
      widget.onCommand('next_set');
    } else if (lowerCommand.contains('complete') ||
        lowerCommand.contains('done') ||
        lowerCommand.contains('finished')) {
      widget.onCommand('complete_exercise');
    } else if (lowerCommand.contains('rest')) {
      final match = RegExp(r'\d+').firstMatch(lowerCommand);
      final seconds = match != null ? int.tryParse(match.group(0)!) : 60;
      widget.onCommand('start_rest:$seconds');
    } else if (lowerCommand.contains('skip') ||
        lowerCommand.contains('next exercise')) {
      widget.onCommand('skip_exercise');
    } else if (lowerCommand.contains('pause') ||
        lowerCommand.contains('stop')) {
      widget.onCommand('pause_workout');
    } else if (lowerCommand.contains('resume') ||
        lowerCommand.contains('continue')) {
      widget.onCommand('resume_workout');
    } else if (lowerCommand.contains('finish') ||
        lowerCommand.contains('end workout')) {
      widget.onCommand('finish_workout');
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('commands')) {
      _showCommandHelp();
    } else {
      _showErrorSnackbar(
        'Command not recognized. Say "help" for available commands.',
      );
    }
  }

  void _showCommandHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LaconicTheme.darkGray,
        title: const Text(
          'Voice Commands',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available commands:',
              style: TextStyle(color: LaconicTheme.silverGray, fontSize: 16),
            ),
            SizedBox(height: 12),
            CommandItem(command: 'Next set', description: 'Start rest timer'),
            CommandItem(
              command: 'Complete/Done',
              description: 'Mark exercise complete',
            ),
            CommandItem(
              command: 'Rest [seconds]',
              description: 'Start custom rest',
            ),
            CommandItem(command: 'Skip', description: 'Skip to next exercise'),
            CommandItem(command: 'Pause/Stop', description: 'Pause workout'),
            CommandItem(
              command: 'Resume/Continue',
              description: 'Resume workout',
            ),
            CommandItem(command: 'Finish workout', description: 'End workout'),
            CommandItem(command: 'Help', description: 'Show this help'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(color: LaconicTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LaconicTheme.accentRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          onPressed: () {
            if (widget.onToggleVisibility != null) {
              widget.onToggleVisibility!();
            }
          },
          backgroundColor: LaconicTheme.ironGray,
          child: const Icon(Icons.mic, color: Colors.white),
        ),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          if (widget.onToggleVisibility != null) {
            widget.onToggleVisibility!();
          }
        },
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildVoiceInterface(), const SizedBox(height: 20)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceInterface() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LaconicTheme.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening ? LaconicTheme.accentRed : LaconicTheme.ironGray,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voice Control',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (widget.onToggleVisibility != null) {
                    widget.onToggleVisibility!();
                  }
                },
                icon: const Icon(Icons.close, color: LaconicTheme.silverGray),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? LaconicTheme.accentRed
                        : LaconicTheme.ironGray,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _isListening ? 'Listening...' : 'Tap to start',
            style: TextStyle(
              color: _isListening
                  ? LaconicTheme.accentRed
                  : LaconicTheme.silverGray,
              fontSize: 16,
            ),
          ),
          if (_lastWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"$_lastWords"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(_confidenceLevel * 100).toInt()}%',
              style: TextStyle(
                color: _confidenceLevel > 0.7
                    ? LaconicTheme.successGreen
                    : LaconicTheme.silverGray,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickCommand(
                'Next Set',
                () => widget.onCommand('next_set'),
              ),
              _buildQuickCommand(
                'Complete',
                () => widget.onCommand('complete_exercise'),
              ),
              _buildQuickCommand(
                'Rest 60s',
                () => widget.onCommand('start_rest:60'),
              ),
              _buildQuickCommand(
                'Skip',
                () => widget.onCommand('skip_exercise'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showCommandHelp,
            child: const Text(
              'View All Commands',
              style: TextStyle(color: LaconicTheme.accentRed, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommand(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: LaconicTheme.ironGray,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class CommandItem extends StatelessWidget {
  final String command;
  final String description;

  const CommandItem({
    super.key,
    required this.command,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: LaconicTheme.accentRed,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: LaconicTheme.silverGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
