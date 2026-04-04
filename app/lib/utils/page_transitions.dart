import 'package:flutter/material.dart';

/// Custom page transitions for fluid animations
class PageTransitions {
  /// Slide transition from right to left
  static PageRouteBuilder slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  /// Scale and fade transition
  static PageRouteBuilder scaleFadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        
        var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
  
  /// Fade transition only
  static PageRouteBuilder fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}

/// Animated widget wrapper for smooth transitions
class AnimatedWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset? slideOffset;
  final bool enableScale;
  final bool enableFade;
  
  const AnimatedWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.slideOffset,
    this.enableScale = false,
    this.enableFade = true,
  });
  
  @override
  State<AnimatedWrapper> createState() => _AnimatedWrapperState();
}

class _AnimatedWrapperState extends State<AnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    if (widget.slideOffset != null) {
      _slideAnimation = Tween<Offset>(
        begin: widget.slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
    }
    
    if (widget.enableScale) {
      _scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
    }
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    
    if (widget.enableFade) {
      child = FadeTransition(
        opacity: _fadeAnimation,
        child: child,
      );
    }
    
    if (widget.slideOffset != null) {
      child = SlideTransition(
        position: _slideAnimation,
        child: child,
      );
    }
    
    if (widget.enableScale) {
      child = ScaleTransition(
        scale: _scaleAnimation,
        child: child,
      );
    }
    
    return child;
  }
}
