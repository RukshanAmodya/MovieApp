import 'package:flutter/material.dart';
import '../core/theme.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: RooflixTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.tv_rounded,
              size: 48,
              color: RooflixTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Series',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
