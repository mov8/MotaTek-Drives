import 'package:flutter/material.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';
import '/tiles/tiles.dart';

class MessagesSummaryForm extends StatefulWidget {
  final List<MailItem> mailItems;
  final Function(int) onTap;
  final Function() onNewContact;
  bool addContact = false;
  MessagesSummaryForm(
      {super.key,
      required this.mailItems,
      required this.onTap,
      required this.onNewContact,
      this.addContact = false});
  @override
  State<MessagesSummaryForm> createState() => _MessagesSummaryFormState();
}

class _MessagesSummaryFormState extends State<MessagesSummaryForm> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (widget.addContact) ...[
        AddContactTile(
          onAddMember: (email) => newContact(add: true, email: email),
          onCancel: (_) => newContact(add: false, email: ''),
        )
      ],
      Expanded(
        child: ListView.builder(
          itemCount: widget.mailItems.length,
          itemBuilder: (context, index) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: InkWell(
              onTap: () => widget.onTap(index),
              child: Card(
                elevation: 5,
                child: ListTile(
                  key: Key('$index'),
                  leading: widget.mailItems[index].isGroup
                      ? Icon(Icons.group, size: 30)
                      : Badge.count(
                          backgroundColor:
                              widget.mailItems[index].unreadMessages > 0
                                  ? const Color.fromRGBO(158, 14, 4, 1)
                                  : const Color.fromARGB(255, 91, 129, 194),
                          textColor: widget.mailItems[index].unreadMessages > 0
                              ? Colors.white
                              : const Color.fromRGBO(241, 238, 238, 1),
                          count: widget.mailItems[index].unreadMessages,
                          child: const Icon(Icons.messenger_outlined, size: 30),
                        ),

                  title: Text(
                    '${widget.mailItems[index].name} ',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'messages received: ${widget.mailItems[index].received}  - sent: ${widget.mailItems[index].sent}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          )
                        ],
                      ),
                      if (!widget.mailItems[index].isGroup)
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'unread messages: ${widget.mailItems[index].unreadMessages}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  ///title: Text(_mailItems[index].name))),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  newContact({required bool add, required String email}) async {
    if (add) {
      GroupMember contact = await getUserByEmail(email);
      String name = '${contact.forename} ${contact.surname}';
      widget.mailItems
          .add(MailItem(id: '', name: name, isGroup: false, email: email));
    }
    widget.onNewContact();
  }

  dismissAction({required int index, required int action}) {}
}
