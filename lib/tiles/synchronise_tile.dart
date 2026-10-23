import 'package:flutter/material.dart';
import '/classes/classes.dart';

class SynchroniseTile extends StatelessWidget {
  @override
  Widget build(BuildContext context, {bool sender = true}) {
    return RrExpansionTile(
        context: context,
        child: ExpansionTile(
          leading: Icon(
            Icons.transfer_within_a_station,
            size: 30,
            color: Colors.blue,
          ),
          title: Column(
            children: [
              Text('WiFi Trip Synchronisation',
                  style: TextStyle(fontSize: 20, color: Colors.blue)),
              Text('Receive a trip',
                  style: TextStyle(fontSize: 20, color: Colors.blue)),
            ],
          ),
          children: [
            Text(
                "When the 4 digit key code appears on the sender's screen, enter it in the box below",
                style: TextStyle(fontSize: 20, color: Colors.blue)),
            SizedBox(height: 10),
            TextField(
              maxLength: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                label: Text('4-Digit Code',
                    style: TextStyle(fontSize: 22, color: Colors.blue)),
              ),
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 30, color: Colors.black),
              onChanged: (value) => {},
            ),
            SizedBox(height: 10),
            Center(
              child: ActionChip(
                label: Text('Send Code',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ));
  }
}
