import 'dart:developer' as developer;
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '/classes/classes.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '../constants.dart';

/// A group drive in progress - the one place that knows about it.
///
/// The other participants are CurrentTripItem().followers, which the map
/// draws (the style's streamed-data source), and the messages are
/// CurrentTripItem().tripMessages. The group drive's id is
/// CurrentTripItem().groupDriveId, which shows the Group and Messages chips.
///
/// Everyone in the drive is in a Socket.IO room named after it. Joining
/// (trip_join) marks the participant as joined on the server and tells the
/// others, with their car's details; positions and messages go out as
/// trip_message and arrive as message_from_trip.
class GroupDriveService {
  static final GroupDriveService _instance = GroupDriveService._();
  factory GroupDriveService() => _instance;
  GroupDriveService._();

  sio.Socket? _socket;

  /// This user's car, from their invitation
  Follower? me;

  /// Messages that arrived while the Messages drawer wasn't showing
  int unread = 0;

  DateTime _lastSent = DateTime(2000);

  bool get active => CurrentTripItem().groupDriveId.isNotEmpty;

  /// Joins the group drive [groupDriveId] - its trip already loaded.
  Future<void> start({required String groupDriveId}) async {
    stop();
    CurrentTripItem().groupDriveId = groupDriveId;
    CurrentTripItem().tripMessages.clear();
    unread = 0;
    await _loadParticipants();
    _connect();
  }

  /// Leaves the group drive
  void stop() {
    String groupDriveId = CurrentTripItem().groupDriveId;
    if (_socket != null) {
      if (_socket!.connected && groupDriveId.isNotEmpty) {
        _socket!.emit('trip_leave', {'trip': groupDriveId});
      }
      _socket!.dispose();
      _socket = null;
    }
    CurrentTripItem().groupDriveId = '';
    CurrentTripItem().followers = [];
    me = null;
    _redraw();
  }

  /// Everyone invited who hasn't declined - each with a colour of their own
  /// for their car on the map
  Future<void> _loadParticipants() async {
    List<Follower> participants = [];
    try {
      participants = await getDrivers(
          groupDriveId: CurrentTripItem().groupDriveId, accepted: 2);
    } catch (e) {
      developer.log('Error loading the group drive: ${e.toString()}',
          name: 'error');
    }
    List<Follower> others = [];
    int colour = 2;
    for (Follower participant in participants) {
      if (participant.accepted == 1) continue; // declined
      colour = colour < 16 ? colour + 1 : 3;
      participant.iconColour = colour;
      if (participant.email == Setup().user.email) {
        me = participant;
      } else {
        others.add(participant);
      }
    }
    me ??= Follower(
      forename: Setup().user.forename,
      surname: Setup().user.surname,
      email: Setup().user.email,
      phoneNumber: Setup().user.phone,
      position: [0, 0],
    );
    CurrentTripItem().followers = others;
    _redraw();
  }

  void _connect() {
    _socket = sio.io(urlBase, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    // Joined again after a dropped connection too - the server keeps the
    // room in the connection's session
    _socket!.onConnect((_) => _join());
    _socket!.onConnectError(
        (e) => developer.log('Group drive connect error: $e', name: 'error'));
    _socket!.on('message_from_trip', (data) => _received(data));
    _socket!.connect();
  }

  void _join() {
    Point position = CurrentTripItem().tripValues.position;
    _socket?.emit('trip_join', {
      'token': Setup().jwt,
      'trip': CurrentTripItem().groupDriveId,
      'make': me?.manufacturer ?? '',
      'model': me?.model ?? '',
      'colour': me?.carColour ?? '',
      'reg': me?.registration ?? '',
      'phone': me?.phoneNumber ?? '',
      'lat': position.y.toDouble(),
      'lng': position.x.toDouble(),
    });
  }

  /// Sends this user's position - at most every 2 seconds, as fixes come
  /// every 5 metres
  void updatePosition(Point position) {
    if (!active || !(_socket?.connected ?? false)) return;
    DateTime now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < 2000) return;
    _lastSent = now;
    _socket!.emit('trip_message', {
      'message': '',
      'lat': position.y.toDouble(),
      'lng': position.x.toDouble(),
    });
  }

  /// A message to everyone in the group drive
  void sendMessage(String message) {
    if (message.trim().isEmpty || !(_socket?.connected ?? false)) return;
    Point position = CurrentTripItem().tripValues.position;
    _socket!.emit('trip_message', {
      'message': message.trim(),
      'lat': position.y.toDouble(),
      'lng': position.x.toDouble(),
    });
  }

  /// A join (type 's'), a position (type 'p', no message) or a message -
  /// this user's own come back from the room too
  void _received(dynamic data) {
    try {
      TripMessage tripMessage =
          TripMessage.fromSocketMap(Map<String, dynamic>.from(data));
      bool mine = tripMessage.email == Setup().user.email;
      if (!mine && ['p', 's'].contains(tripMessage.type)) {
        _moveFollower(tripMessage);
      }
      if (tripMessage.message.isNotEmpty && tripMessage.message != 'join') {
        Follower? follower = mine ? me : _follower(tripMessage.email);
        tripMessage.manufacturer = follower?.manufacturer ?? '';
        tripMessage.model = follower?.model ?? '';
        tripMessage.carColour = follower?.carColour ?? '';
        tripMessage.registration = follower?.registration ?? '';
        CurrentTripItem().tripMessages.add(tripMessage);
        if (!mine) unread++;
        _refreshDrawer(BottomDrawerItems.tripMessages);
      }
    } catch (e) {
      developer.log('Error with a group drive message: ${e.toString()}',
          name: 'error');
    }
  }

  Follower? _follower(String email) {
    for (Follower follower in CurrentTripItem().followers) {
      if (follower.email == email) return follower;
    }
    return null;
  }

  void _moveFollower(TripMessage tripMessage) {
    Follower? follower = _follower(tripMessage.email);
    if (follower == null) {
      // Joined without an invitation showing - e.g. the organiser
      if (tripMessage.type != 's') return;
      follower = Follower(
        forename: tripMessage.sender,
        email: tripMessage.email,
        iconColour: 3 + CurrentTripItem().followers.length % 14,
        position: [0, 0],
      );
      CurrentTripItem().followers.add(follower);
    }
    if (tripMessage.type == 's') {
      follower.accepted = 3; // joined
      if (tripMessage.manufacturer.isNotEmpty) {
        follower.manufacturer = tripMessage.manufacturer;
        follower.model = tripMessage.model;
        follower.carColour = tripMessage.carColour;
        follower.registration = tripMessage.registration;
      }
      if (tripMessage.phoneNumber.isNotEmpty) {
        follower.phoneNumber = tripMessage.phoneNumber;
      }
      _refreshDrawer(BottomDrawerItems.group);
    }
    if (tripMessage.lat != 0 && tripMessage.lng != 0) {
      follower.position = [tripMessage.lng, tripMessage.lat];
      follower.reported = DateTime.now();
      _redraw();
    }
  }

  void _redraw() {
    if (MapService().controller == null) return;
    MapService().updateMapGeoJson(mapUpdates: MapUpdates.followers);
  }

  /// Refreshes the drawer if it's showing the group or the messages
  void _refreshDrawer(BottomDrawerItems content) {
    if (MapService().sideDrawerController?.content == content) {
      MapService().sideDrawerController?.setContent(
          content: content,
          drawerItems:
              content == BottomDrawerItems.group ? CurrentTripItem().followers : null);
    }
    if (MapService().bottomDrawerController?.content == content) {
      MapService().bottomDrawerController?.setContent(
          content: content,
          drawerItems:
              content == BottomDrawerItems.group ? CurrentTripItem().followers : null,
          open: false);
    }
  }
}
