/*
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';

class ExpansionTileList extends StatefulWidget {
  final Function(double)? onChangeHeight;
  final double maxHeight;
  final double height;
  final double closedTop;
  final double dividerHeight;
  final ScrollController? controller;
  List<Card> cards;
  List<bool>? expanded;

  const ExpansionTileList(
      {super.key, required this.cards, this.controller, this.expanded});

  @override
  State<ExpansionTileList> createState() => _ExpansionTileList();
}

class _ExpansionTileList extends State<ExpansionTileList> {
  double height = 0;
  double contentBottom = 0;
  double contentHeight = 0;
  int delay = 500;
  final ScrollController _controller = ScrollController();
  final GlobalKey _key = GlobalKey();

  void initState() {
    super.initState;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget? cardsList(
      {required List<Card> cards, required ScrollController controller}) {
    Widget? scrollList;
    try {
      if (cards.isNotEmpty) {
        scrollList = ListView.builder(
          controller: controller,
          itemCount: cards.length,
          itemBuilder: (context, index) =>
              cards[index < cards.length ? index : cards.length - 1],
        );
      }
    } catch (e) {
      debugPrint('Error building scrollList ${e.toString()}');
    }
    return scrollList;
  }
}
*/
