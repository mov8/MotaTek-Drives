import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final int _delaySecs = 4;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, //Color.fromRGBO(2, 46, 75, 0),
      body: Builder(
        builder: (BuildContext context) => _getPortraitBody(),
      ),
    );
  }

  Future<void> initialise() async {
    if (!NavigationService().showSplash) return;
    NavigationService().showSplash = false;
    int routeIndex = Setup().bottomNavIndex;

    if (routeIndex != 0) {
      Setup().bottomNavIndex = 0;
    }
    await MapService().loadStyle();

    if (Setup().jwt.isEmpty) {
      Setup().loggingIn = true;
      await Login(context: context).tryLoggingIn();
    }

    await Future.delayed(Duration(seconds: _delaySecs));
    if (kIsWeb) {
      MapService().webAppBarController?.showControls();
      MapService().sideDrawerController?.setFixed(fixed: true);
      MapService().sideDrawerController?.open();
      MapService().sideDrawerController?.setVisible(visible: true);
    }

    if (mounted) {
      setState(() {});
    } else {}
  }

  Widget _getPortraitBody() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initialise());
    Size screenSize = MediaQuery.of(context).size;

    double aspectRatio = screenSize.width / screenSize.height;
    aspectRatio = aspectRatio > 1 ? 9 / 18 : aspectRatio;

    return Stack(
      children: [
        Center(
          child: Text('Hi'),
        )
      ],
    );
  }
}
