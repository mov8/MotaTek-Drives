import 'dart:math';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../classes/classes.dart';
import '../services/services.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

// Web version
//  1. Connects anonymously to Socket.IO.                                  │
//  2. Displays temporary 4-digit code on screen (e.g. "8842").

// Mobile version
//  1. User enters "8842" on phone screen.                                 │
//  2. Socket.IO hands PC Web the mobile's IP (192.168.1.88:8080).         │
//  3. Phone starts Shelf server with GET/POST download endpoints.

//  • PC Web fetches trip archive directly via standard browser GET request:│
//    `http://192.168.1.88:8080/download-trip`                             │
//  • Web app unpacks `.trip` zip in browser memory (`archive` package).    │
//  • Saves trip directly into Hive / IndexedDB on Web.

class ImportExport extends StatelessWidget {
  final MyTripItem? tripItem;

  /// Called instead of popping the route when the screen isn't a route of
  /// its own - on the web it's shown in the SideDrawer
  final VoidCallback? onClose;
  const ImportExport({super.key, this.tripItem, this.onClose});

  void _close(BuildContext context) =>
      onClose != null ? onClose!() : context.pop();

  // Mobile_arrow_down / up_right
  @override
  Widget build(BuildContext context) {
    sio.Socket socket = sio.io(urlBase, <String, dynamic>{
      // sio.Socket socket = sio.io('http://192.168.1.10:5000', <String, dynamic>{
      'transports': ['websocket'], // Specify WebSocket transport
      'autoConnect': false, // Prevent auto-connection
    });
    String _key = getRandomInt(1000, 9999).toString();
    socket.onConnectError((_) => debugPrint('connect error'));
    socket.onError((data) =>
        developer.log('socket error: ${data.toString()}', name: 'error'));
    if (kIsWeb) {
      socket.onConnect((_) {
        socket.emit('pairing', {'message': 'web connected'});
      });
    } else {
      socket.onConnect((_) {
        socket.emit('pairing', {'message': 'device connected'});
      });
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _close(context),
          ),
        ),
        backgroundColor: Colors.blue,
        body: mobileUser(context, socket, _key),
        resizeToAvoidBottomInset: true);
  }

  int getRandomInt(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  Widget mobileUser(context, sio.Socket socket, String code) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/transfer.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5), // // Light shadow top
                  Colors.black.withValues(alpha: 0.7), // Dark contrast bottom
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Drives Guest WiFi Synchronisation',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 20),
                Text(
                    'Synchronise is specifically for the Browser version of Drives to synchronise data with the mobile version.',
                    style: TextStyle(fontSize: 22, color: Colors.white)),

                SizedBox(height: 20),
                Text(
                    'Both the sender and receiver must be running Drives on the same WiFi network.',
                    style: TextStyle(fontSize: 22, color: Colors.white)),
                SizedBox(height: 10),
                if (tripItem == null) ...[
                  Text(
                      "In the Favourites screen on your ${kIsWeb ? 'device' : 'PC'} open the details of the trip you want to send and tap the Synchronise button to show this screen.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 10),
                ],

                if (tripItem != null) ...[
                  Text(
                      "Open the trip Explore screen on your ${kIsWeb ? 'device' : 'PC'} and tap the Synchronise button at the top right hand side.",
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 10),
                ],

                if (kIsWeb) ...[
                  Text(
                      'The following 4 digit code must be typed into the Synchronise screen of your device. Please note that the link will expire after 5 minutes.',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: Container(
                        width: 100,
                        height: 40,
                        color: Colors.white,
                        child: Text('1234',
                            style:
                                TextStyle(fontSize: 38, color: Colors.black)),
                      ),
                    ),
                  ),
                ], // <-- kIsWeb
                if (!kIsWeb) ...[
                  SizedBox(height: 10),
                  Text(
                      'In this Synchronise screen on your PC you will see a 4-digit code. Enter it into the box below and tap proceed.',
                      style: TextStyle(fontSize: 22, color: Colors.white)),
                  SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 100,
                      child: TextField(
                        maxLength: 4,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText:
                                "${'\u25CF'}${'\u25CF'}${'\u25CF'}${'\u25CF'}"),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            letterSpacing: 2),
                        onChanged: (value) => {},
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 10),
                Text("Register now to synchronise automatically.",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(
                    "It's FREE, and allows you to share trips with friends, club members and the rest of the world.",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        flex: 5,
                        child: ActionChip(
                          label: Text('Proceed',
                              style:
                                  TextStyle(fontSize: 22, color: Colors.white)),
                          backgroundColor: Colors.blue,
                          onPressed: () => transfer(socket, code),
                        )),
                    Expanded(
                      flex: 5,
                      child: ActionChip(
                        label: Text('Register',
                            style:
                                TextStyle(fontSize: 22, color: Colors.white)),
                        backgroundColor: Colors.blue,
                        onPressed: () => _close(context),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 650),
              ],
            ),
          ),
        ),
        Positioned(bottom: 0, child: SizedBox(height: 1))
      ],
    );
  }

  Future<void> transfer(sio.Socket socket, String code) async {
    /// If kIsWeb the send the 4-digit code
    /// If !kIsWeb send the ip address
    if (!kIsWeb) {
      WifiReceiverService wifi = WifiReceiverService();
      String ipAddress = await wifi.getIPaddress();
      socket.emit('pairing', {'ip_address': ipAddress});
    } else {
      socket.emit('pairing', {'code': code});
    }
    socket.connect();
    return;
  }

  Future<bool> getTrip() async {
    return true;
  }

  Future<bool> sendTrip() async {
    if (kIsWeb && tripItem != null) {
      if (tripItem!.imageUrls.isNotEmpty) {
        WifiReceiverService wifiService = WifiReceiverService();
        await wifiService.startServer(
            onFileReceived: (_) => {}, onError: (_) => {});
      }
    }
    return true;
  }
}
