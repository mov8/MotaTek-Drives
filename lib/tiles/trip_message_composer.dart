import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '../constants.dart';

/// Sending a message to everyone in the group drive: the predefined
/// messages (contactChoices) are one tap each, so a driver needn't type.
/// Typing is for passengers, or when stopped - moving, it asks first.
class TripMessageComposer extends StatefulWidget {
  const TripMessageComposer({super.key});

  @override
  State<TripMessageComposer> createState() => _TripMessageComposerState();
}

class _TripMessageComposerState extends State<TripMessageComposer> {
  bool _typing = false;
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String message) {
    GroupDriveService().sendMessage(message);
    _text.clear();
    setState(() => _typing = false);
  }

  /// Moving (over 5 mph) - typing is only safe for a passenger
  Future<void> _startTyping() async {
    if (CurrentTripItem().tripValues.speed > 5) {
      bool? passenger = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you a passenger?'),
          content: const Text(
              "Please don't type while driving. Use the messages above, or "
              'wait until you have stopped.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("I'm a passenger")),
          ],
        ),
      );
      if (passenger != true) return;
    }
    setState(() => _typing = true);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (String message in contactChoices)
                  ActionChip(
                    label: Text(message),
                    onPressed: () => _send(message),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 18),
                  label: const Text('Write a message'),
                  onPressed: _startTyping,
                ),
              ],
            ),
            if (_typing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Message to the group',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _send(_text.text),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
