import 'package:flutter/material.dart';
import '/classes/classes.dart';
import '/services/services.dart';

/// Admin (web only): stops a user using Drives. The API disables the
/// account - the email and login are scrambled, so they can't log in -
/// and leaves their published trips, which Remove trips deletes. (It used to
/// offer to remove their trips, points of interest, roads, ratings and
/// groups too, which the API ignored. What happens to a user's data is for
/// the club admin work.)
class DeleteUserForm extends StatefulWidget {
  const DeleteUserForm({super.key});

  @override
  State<DeleteUserForm> createState() => _DeleteUserFormState();
}

class _DeleteUserFormState extends State<DeleteUserForm> {
  late AutoCompleteAsyncController _controller;
  final List<String> dropdownOptions = [];
  String _email = '';

  @override
  void initState() {
    super.initState();
    _controller = AutoCompleteAsyncController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreensAppBarBottom(
      heading: 'Remove user',
      prompt: 'Stop a user using Drives',
      textColor: const Color.fromRGBO(1, 29, 51, 1),
      content: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutocompleteAsync(
              controller: _controller,
              options: dropdownOptions,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter the user's email address",
                labelText: 'Email address',
              ),
              keyboardType: TextInputType.emailAddress,
              onSelect: (chosen) => setState(() => _email = chosen),
              onChange: (text) => setState(() => _email = text),
              onUpdateOptionsRequest: (query) => getDropdownItems(query),
            ),
            const SizedBox(height: 20),
            const Text(
                "Their account is disabled: they can't log in again with this "
                'email. Their published trips stay - remove them with Remove '
                'trips.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ActionChip(
              onPressed: _email.contains('@') ? _confirmRemove : null,
              backgroundColor: Colors.blue,
              disabledColor: Colors.blue.shade200, // until there's something to remove
              avatar: const Icon(Icons.person_off_outlined, color: Colors.white),
              label: const Text('Remove user',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getDropdownItems(String query) async {
    dropdownOptions
      ..clear()
      ..addAll(await getApiOptions(value: query));
    if (mounted) setState(() {});
  }

  Future<void> _confirmRemove() async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $_email?'),
        content: const Text("They won't be able to log in to Drives again."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    bool removed = await deleteWebUser(uriMap: {'email': _email});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(removed
            ? '$_email has been removed'
            : "$_email couldn't be removed")));
    if (removed) {
      setState(() {
        _email = '';
        dropdownOptions.clear();
      });
    }
  }
}
