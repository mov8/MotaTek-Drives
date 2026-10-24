// Tests for reading the API's conversations and messages.
//
// Run with:   flutter test test/models/messages_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/models/other_models.dart';

void main() {
  group('MailItem.fromMap (message/all_messages)', () {
    test('a person: the counts are strings, and the email is kept', () {
      // Without the email a reply had no one to go to
      MailItem item = MailItem.fromMap({
        'id': 'u1',
        'group': 0,
        'name': 'Ada Admin',
        'email': 'ada@example.com',
        'sent': '1',
        'received': '3',
        'read': '1',
      });
      expect(item.isGroup, isFalse);
      expect(item.email, 'ada@example.com');
      expect(item.received, 3);
      expect(item.unreadMessages, 2);
    });

    test('a group', () {
      MailItem item = MailItem.fromMap({
        'id': 'g1',
        'group': 1,
        'name': 'MG Club',
        'email': '',
        'sent': '0',
        'received': '0',
        'read': '0',
      });
      expect(item.isGroup, isTrue);
      expect(item.id, 'g1');
      expect(item.unreadMessages, 0);
    });
  });

  group('Message.fromSocketMap', () {
    test('someone else\'s message is received, not sent', () {
      Message message = Message.fromSocketMap({
        'sender': 'Mo Member',
        'message': 'Meet at 9',
        'email': 'mo@example.com',
        'group_id': 'g1',
      });
      expect(message.message, 'Meet at 9');
      expect(message.sender, 'Mo Member');
      expect(message.sent, isFalse);
    });
  });
}
