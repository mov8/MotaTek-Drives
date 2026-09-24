import 'package:flutter/material.dart';
import '../constants.dart';
// import 'dart:developer' as developer;

class MapBottomSheet extends StatefulWidget {
  const MapBottomSheet({super.key});

  @override
  State<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends State<MapBottomSheet> {
  bool _isSheetContentExpanded = false;

  void _toggleSheet() {
    setState(() {
      _isSheetContentExpanded = !_isSheetContentExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Prevents taking up full screen unless open
        children: [
          // 3. THE TAPPABLE / DRAGGABLE BAR
          GestureDetector(
            onTap:
                _toggleSheet, // Clicking this smoothly opens/closes the drawer
            onVerticalDragEnd: (details) {
              // Quick drag gesture checking: swipe up to open, swipe down to close
              if (details.primaryVelocity! < 0 && !_isSheetContentExpanded) {
                _toggleSheet();
              } else if (details.primaryVelocity! > 0 &&
                  _isSheetContentExpanded) {
                _toggleSheet();
              }
            },
            child: Container(
              width: double.infinity,
              color: Colors.blueGrey,
              // .transparent, // Ensures the entire bar width is interactive
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400], // Clean visual pill asset
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // 4. THE DATA CONTENT ZONE
          // AnimatedCrossFade handles animating your list smoothly out of view
          // without leaving weird data text fragments visible when closed.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 500),
            crossFadeState: _isSheetContentExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            // WHAT SHOWS WHEN EXPANDED: Your full scrolling API list data
            firstChild: Container(
              constraints: BoxConstraints(
                // Locks the drawer to exactly 45% of whatever screen height they have
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 15,
                itemBuilder: (context, index) => ListTile(
                  title: Text("Beta API Item Data $index"),
                ),
              ),
            ),
            // WHAT SHOWS WHEN CLOSED: Absolutely nothing (SizedBox with 0 height)
            // This makes the drag bar sit flush right against your bottom navigation bar!
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class MapBottomSheet2 extends StatefulWidget {
  const MapBottomSheet2({super.key});

  @override
  State<MapBottomSheet2> createState() => _MapBottomSheet2State();
}

class _MapBottomSheet2State extends State<MapBottomSheet2> {
  // 1. Create a controller to programmatically open/close the sheet on tap
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isOpen = false;

  void _toggleSheet() {
    setState(() {
      _isOpen = !_isOpen;
      // Animate perfectly between collapsed (10% height) and expanded (60% height)
      _sheetController.animateTo(
        _isOpen ? 0.6 : 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return // Scaffold(
        // The Stack keeps your MapLibre map underneath the sheet
        //  body: //Stack(
        //children: [
        //  const Center(child: Text("Your Maplibre GL Map Lives Here")),

        // 2. The Native Draggable Sheet
        DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.05, // Starts collapsed (10% of screen height)
      minChildSize: 0.05, // Minimum height
      maxChildSize: 0.6, // Maximum height (60% of screen)
      snap: true, // Automatically snaps to bounds when released
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              // 3. YOUR DRAGGABLE / TAPPABLE GRAB BAR
              GestureDetector(
                onTap: _toggleSheet, // Tapping this snaps it open/closed
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200], // Background of the bar zone
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors
                            .grey[600], // The physical "pill" visual asset
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. THE CONTENT ZONE
              Expanded(
                child: ListView.builder(
                  // CRITICAL: Pass this scrollController to your list
                  // so dragging the list data also moves the sheet!
                  controller: scrollController,
                  itemCount: 20,
                  itemBuilder: (context, index) => ListTile(
                    title: Text("Ancillary Data Item $index"),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      // ),
      //  ],
      // ),
    );
  }
}
