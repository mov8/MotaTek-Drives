import 'dart:async';
import 'package:drives/main.dart';
import 'package:flutter/foundation.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart';
import '../constants.dart';
import 'dart:developer' as developer;

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final int _delaySecs = 4;
  bool _initialised = false;
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) => initialise());
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
    developer.log('Initialise called', name: '_splash_');
    if (!UIStateService().showSplash) return;

    int routeIndex = Setup().bottomNavIndex;

    if (routeIndex != 0) {
      Setup().bottomNavIndex = 0;
      //   Setup().setupToDb();
    }
    //  routeIndex = 4;
    await MapService().loadStyle();
    developer.log('Style loaded', name: '_splash_');
    if (Setup().jwt.isEmpty) {
      Setup().loggingIn = true;
      await Login(context: context).tryLoggingIn();
    }
    developer.log('Gone past login', name: '_splash_');
    await Future.delayed(Duration(seconds: _delaySecs));
    if (kIsWeb) {
      MapService().webAppBarController?.showControls();
      MapService().sideDrawerController?.setFixed(fixed: true);
      MapService().sideDrawerController?.open();
      MapService().sideDrawerController?.setVisible(visible: true);
    }
    developer.log('MapService() controllers loaded', name: '_splash_');
    if (mounted) {
      developer.log('mounted = true', name: '_splash_');
      setState(() {
        UIStateService().setPage(0);
        NavigationService().navigateTo(routes[0], null);
      });
    } else {
      developer.log('mounted = false', name: '_splash_');
      NavigationService().navigateTo(routes[0], null);
      UIStateService().setPage(0); // <-- Page not Widget
    }
    UIStateService().showSplash = false;
  }

  Widget _getPortraitBody() {
    WidgetsBinding.instance.addPostFrameCallback((_) => initialise());
    Size screenSize = MediaQuery.of(context).size;

    double aspectRatio = screenSize.width / screenSize.height;
    aspectRatio = aspectRatio > 1 ? 9 / 18 : aspectRatio;
    double paddingLR = kIsWeb ? 0 : 0;
    double paddingTB = kIsWeb ? 50 : 0;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(
                paddingLR, paddingTB, paddingLR, paddingTB),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Image(
                image: AssetImage('assets/images/splash.png'),
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.center,
              ),
            ),
          ),
        )
      ],
    );
  }
}
