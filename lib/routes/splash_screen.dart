import 'dart:async';
import 'package:drives/main.dart';
import 'package:flutter/foundation.dart';
import '../services/services.dart';
import 'package:flutter/material.dart';
import '/models/models.dart';
import '/classes/classes.dart';
import '../constants.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => initialise());
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
    if (Setup().jwt.isEmpty) {
      Setup().loggingIn = true;
      await Login(context: context).tryLoggingIn();
    }
    await Future.delayed(Duration(seconds: _delaySecs));
    int routeIndex = Setup().bottomNavIndex;

    if (routeIndex != 0) {
      Setup().bottomNavIndex = 0;
      //   Setup().setupToDb();
    }
    //  routeIndex = 4;
    await MapService().loadStyle();

    MapService().webAppBarController?.showControls();
    MapService().sideDrawerController?.setFixed(fixed: true);
    MapService().sideDrawerController?.open();
    MapService().sideDrawerController?.setVisible(visible: true);

    if (mounted) {
      NavigationService().navigateTo(routes[0], null);
      UIStateService().setPage(1);
    }
  }

  Widget _getPortraitBody() {
    //Size screenSize = MediaQuery.of(context).size;
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
