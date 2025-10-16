import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:drives/models/models.dart';

class NetworkState extends StatelessWidget {
  final List<ConnectivityResult> _status = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _statusSubscription;

  NetworkState._privateConstructor();
  static final _instance = NetworkState._privateConstructor();
  factory NetworkState() {
    return _instance;
  }
  final List<Icon> icons = [
    Icon(Icons.account_circle_outlined),
    Icon(Icons.no_accounts_outlined),
    Icon(Icons.wifi_outlined),
    Icon(Icons.wifi_off_outlined),
    Icon(Icons.signal_cellular_4_bar_outlined),
    Icon(Icons.signal_cellular_connected_no_internet_0_bar)
  ];
  bool changed = false;
  final List<int> iconIndexes = [0, 2, 4, -1];

  @override
  Widget build(BuildContext context) {
    initConnectivity();
    _statusSubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    return getIcons();
  }

  void initialise() {
    if (iconIndexes[3] == -1) {
      initConnectivity();
      _statusSubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      iconIndexes[3] = 0;
    }
  }

  Widget getIcons({Function(bool)? onUpdate}) {
    onUpdate!(changed);
    return Wrap(spacing: 5, children: [
      icons[iconIndexes[0]],
      icons[iconIndexes[1]],
      icons[iconIndexes[2]],
      SizedBox(width: 5),
    ]);
  }

  void onDispose() {
    _statusSubscription.cancel();
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    //  setState(() {
    //    _connectionStatus = result;
    //  });
    // ignore: avoid_print
    developer.log('Updating the network status', name: '_network');
    iconIndexes[0] = Setup().loggingIn ? 0 : 1;
    iconIndexes[1] = _status.contains(ConnectivityResult.wifi) ? 2 : 3;
    iconIndexes[2] = _status.contains(ConnectivityResult.mobile) ? 4 : 5;
    changed = true;
    // print('Connectivity changed: $_status');
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    //  if (!mounted) {
    //    return Future.value(null);
    //  }

    return _updateConnectionStatus(result);
  }
}
