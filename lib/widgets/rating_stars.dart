import 'package:flutter/material.dart';

/// Read-only star rating row.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i;
        return Icon(
          filled
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          size: size,
          color: Colors.amber.shade700,
        );
      }),
    );
  }
}

/// Interactive star input for the review form.
class RatingInput extends StatefulWidget {
  final int initial;
  final ValueChanged<int> onChanged;

  const RatingInput({super.key, this.initial = 5, required this.onChanged});

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          onPressed: () {
            setState(() => _value = star);
            widget.onChanged(star);
          },
          icon: Icon(
            star <= _value ? Icons.star : Icons.star_border,
            size: 40,
            color: Colors.amber.shade700,
          ),
        );
      }),
    );
  }
}
