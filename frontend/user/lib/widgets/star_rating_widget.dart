import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.activeColor = const Color(0xFFFFA500),
    this.inactiveColor = const Color(0xFF9CA3AF),
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return Text(
          _getStarIcon(index + 1),
          style: TextStyle(
            fontSize: size,
            color: _getStarColor(index + 1),
            height: 1.0,
          ),
        );
      }),
    );
  }

  String _getStarIcon(int position) {
    if (rating >= position) {
      return '★'; // Filled star
    } else if (allowHalfRating && rating >= position - 0.5) {
      return '★'; // Half star shown as filled
    } else {
      return '☆'; // Empty star
    }
  }

  Color _getStarColor(int position) {
    if (rating >= position || 
        (allowHalfRating && rating >= position - 0.5)) {
      return activeColor;
    } else {
      return inactiveColor;
    }
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
    this.activeColor = const Color(0xFFFFA500),
    this.inactiveColor = const Color(0xFF6B7280),
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starPosition = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starPosition;
            });
            widget.onRatingChanged(starPosition);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              starPosition <= _currentRating ? '★' : '☆',
              style: TextStyle(
                fontSize: widget.size,
                color: starPosition <= _currentRating 
                    ? widget.activeColor 
                    : widget.inactiveColor,
                height: 1.0,
              ),
            ),
          ),
        );
      }),
    );
  }
}
