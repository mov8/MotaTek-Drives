import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class SoftNudgeBanner extends StatefulWidget {
  const SoftNudgeBanner({super.key});

  @override
  State<SoftNudgeBanner> createState() => _SoftNudgeBannerState();
}

class _SoftNudgeBannerState extends State<SoftNudgeBanner> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    // If user logs in via your singleton later, you can auto-hide this too:
    // if (AppDataCache.instance.isLoggedIn) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isVisible
          ? Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Use a soft, premium accent colour instead of a harsh warning red
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100, width: 1),
              ),
              child: Row(
                children: [
                  // An icon that shows value/contribution
                  Icon(Icons.cloud_upload_outlined,
                      color: Colors.blue.shade700),
                  const SizedBox(width: 12),

                  // The Persuasion Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Want to contribute?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Create a free account to share your trips.",
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // The Action Button
                  TextButton(
                    onPressed: () {
                      // Use push so the browser back button safely drops them back to the map
                      //  context.push('/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child:
                        const Text("Sign Up", style: TextStyle(fontSize: 13)),
                  ),

                  // The Close Button
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 18, color: Colors.blue.shade400),
                    onPressed: () {
                      setState(() {
                        _isVisible = false; // Collapses the widget smoothly
                      });
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(), // Takes up 0px space when dismissed
    );
  }
}
