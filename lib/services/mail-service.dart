import 'dart:async';

// import 'package:enough_mail/enough_mail.dart';

import '../mail-client/enough_mail.dart';
import 'package:mail_app/utils/wait-until.dart';

class CustomMailClient {
  final ImapClient _client = ImapClient(isLogEnabled: false);

  final Map<String, List<MimeMessage>> _messages = {};
  late List<Mailbox> _mailBoxes;
  late Mailbox _currentMailbox;
  late String _email;

  bool _connected = false;

  List<MimeMessage> getMessages() {
    return _messages[_currentMailbox.encodedPath]!;
  }

  MimeMessage getMessageFromIdx(int idx) {
    if (_messages.containsKey(_currentMailbox.encodedPath) &&
        _messages[_currentMailbox.encodedPath]!.isNotEmpty) {
      return _messages[_currentMailbox.encodedPath]![idx];
    } else {
      return MimeMessage();
    }
  }

  Future<bool> connected() async {
    return await waitUntil(() => _connected);
  }

  bool isConnected() {
    return _connected;
  }

  String getEmail() {
    return _email;
  }

  Future<bool> connect(String email, String password) async {
    try {
      _email = email;

      await _client.connectToServer('imap.gmail.com', 993, isSecure: true);
      await _client.login(email, password);
      _currentMailbox = await _client.selectInbox();
      await updateMailBoxes();

      // handle fetching cached/ saved messages

      _connected = true;
    } on ImapException catch (e) {
      print(e);
    }

    return _connected;
  }

  Future<bool> disconnect() async {
    try {
      await _client.logout();

      _connected = false;
    } on ImapException catch (e) {
      print(e);
    }

    return _connected;
  }

  void selectLocalMailbox(String mailboxPath) {
    _currentMailbox = getMailboxFromPath(mailboxPath);

    print(_currentMailbox);
  }

  Future<void> selectMailbox(String mailboxPath) async {
    try {
      await _client.selectMailbox(getMailboxFromPath(mailboxPath));
    } on ImapException catch (e) {
      print(e);
    }
  }

  Future<void> updateMailboxFromPath(String mailboxPath) async {
    try {
      await _client.selectMailbox(getMailboxFromPath(mailboxPath));

      final SearchImapResult sequenceFetch =
          await _client.searchMessages(searchCriteria: 'ALL');

      if (sequenceFetch.matchingSequence != null &&
          sequenceFetch.matchingSequence!.isNotEmpty) {
        final FetchImapResult fetchResult = await _client.fetchMessages(
            sequenceFetch.matchingSequence!, 'BODY.PEEK[]');

        _messages[_currentMailbox.encodedPath] = fetchResult.messages;
      }
    } on ImapException catch (e) {
      print(e);
    }
  }

  Future<void> updateMailbox(Mailbox? mailbox) async {
    try {
      if (mailbox != null) {
        _client.selectMailbox(mailbox);
      } else {
        await _client.selectMailbox(_currentMailbox);
      }

      final SearchImapResult sequenceFetch =
          await _client.searchMessages(searchCriteria: 'ALL');

      if (sequenceFetch.matchingSequence != null &&
          sequenceFetch.matchingSequence!.isNotEmpty) {
        final FetchImapResult fetchResult = await _client.fetchMessages(
            sequenceFetch.matchingSequence!, 'BODY.PEEK[]');

        _messages[_currentMailbox.encodedPath] = fetchResult.messages;
      }
    } on ImapException catch (e) {
      print(e);
    }
  }

  Future<void> updateMailBoxes() async {
    _mailBoxes = await _client.listMailboxes(recursive: true);

    for (var mailbox in _mailBoxes) {
      if (mailbox.encodedName.endsWith(']')) {
        continue;
      }

      if (!_messages.containsKey(mailbox.encodedPath)) {
        _messages[mailbox.encodedPath] = [];
      }

      await updateMailbox(mailbox);

      _client.selectMailbox(_currentMailbox);
    }
  }

  List<Mailbox> getMailBoxes() {
    return _mailBoxes;
  }

  List<String> getMailBoxNames() {
    return _mailBoxes.map((box) => box.encodedPath).toList(growable: false);
  }

  Mailbox getMailboxFromPath(String mailboxPath) {
    return _mailBoxes
        .where((mailbox) => mailbox.encodedPath == mailboxPath)
        .first;
  }

  // Future<void> discoverExample() async {
  //   var email = 't.brouwer1@student.tue.nl';
  //   var config = await Discover.discover(email, isLogEnabled: false);
  //   if (config == null) {
  //   } else {
  //     for (var provider in config.emailProviders!) {}
  //   }
  // }

  // Future<bool> imapExample() async {
  //   try {
  //     await _client.selectInbox();
  //     // fetch 10 most recent messages:
  //     final fetchResult = await _client.fetchRecentMessages(
  //         messageCount: 100, criteria: 'BODY[]');

  //     _messages["INBOX"] = fetchResult.messages;

  //     return true;
  //   } on ImapException catch (e) {
  //     print(e);
  //   }

  //   return false;
  // }
}