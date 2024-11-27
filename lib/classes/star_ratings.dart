import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final Function onRatingChanged;
  final double rating;
  final int starCount;

  const StarRating({
    super.key,
    required this.onRatingChanged,
    required this.rating,
    this.starCount = 5,
  });

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    if (index >= rating) {
      icon = Icon(Icons.star_border,
          color: Theme.of(context).primaryColor); // Theme.of(context).);
    } else if (index > rating - 1 && index < rating) {
      icon = Icon(Icons.star_half, color: Theme.of(context).primaryColor);
    } else {
      icon = Icon(Icons.star, color: Theme.of(context).primaryColor);
    }
    return InkResponse(
      onTap: () => onRatingChanged(index + 1),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        starCount,
        (index) => buildStar(context, index),
      ),
    );
  }
}
