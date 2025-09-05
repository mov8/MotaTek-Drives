import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/constants.dart';
import 'package:drives/classes/classes.dart';
import 'package:drives/services/services.dart';
import 'dart:developer' as developer;

/// InviteMember handles the adding of a new member to a group there are 2 options:
///   The invitee is already registered
///     InviteMember adds member to the Group class to be sent to API on confirmed update
///   The invitee is new
///     InviteMember sends an invitation email to the prospective member
///
class AddContactTileController {
  _AddContactTileState? _addContactTileState;

  void _addState(_AddContactTileState addContactTileState) {
    _addContactTileState = addContactTileState;
  }

  bool get isAttached => _addContactTileState != null;

  void leave() {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      //    _addContactTileState?.leave();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class AddContactTile extends StatefulWidget {
  final Function(bool)? onCancel;
  final Function(String)? onAddMember;
  // final GroupMember newMember;
  final Color color;
  final double elevation;
  const AddContactTile(
      {super.key,
      this.onCancel,
      this.onAddMember,
      this.color = Colors.white,
      this.elevation = 5});
  @override
  State<AddContactTile> createState() => _AddContactTileState();
}

class _AddContactTileState extends State<AddContactTile> {
  final List<String> _dropdownOptions = [];
  List<bool> _fieldStates = [false, false, false];
  late AutoCompleteAsyncController _controller1;
  late TextEditingController _controller2;
  late FocusNode _focusNode1;
  late GroupMemberState _groupMemberState;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _controller1 = AutoCompleteAsyncController();
    _controller2 = TextEditingController();
    _focusNode1 = FocusNode();
    _groupMemberState = GroupMemberState.none;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller1.setFocus());
  }

  @override
  void dispose() {
    _controller2.dispose();
    _focusNode1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_email.isEmpty) {
      _focusNode1.requestFocus();
    }
    developer.log('rebuild: _groupMemberState: ${_groupMemberState.toString()}',
        name: '_state');
    return Card(
      elevation: widget.elevation,
      surfaceTintColor: widget.color,
      child: ListTile(
        title: Text(
          "Email address of Drives user to add",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: AutocompleteAsync(
                          controller: _controller1,
                          options: _dropdownOptions,
                          searchLength: 1,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter users email address',
                            labelText: 'Email address',
                            suffixIcon: _fieldStates[2]
                                ? IconButton(
                                    icon: Icon(Icons.check_circle_outline),
                                    onPressed: () => {
                                      if (widget.onAddMember != null)
                                        {widget.onAddMember!(_email)},
                                    },
                                  )
                                : IconButton(
                                    icon: Icon(Icons.cancel_outlined),
                                    onPressed: () => {
                                      if (widget.onCancel != null)
                                        widget.onCancel!(true),
                                    },
                                  ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSelect: (chosen) async {
                            _groupMemberState = GroupMemberState.resistered;
                            await addMemberFromApi(email: chosen);
                            setState(() => _groupMemberState =
                                GroupMemberState.resistered);
                          },
                          onChange: (text) {
                            _email = text;
                            dataComplete();
                          },
                          onUpdateOptionsRequest: (query) =>
                              getDropdownItems(query),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool dataComplete() {
    developer.log(
        'dataComplete start _groupMemberState: ${_groupMemberState.toString()}',
        name: '_state');
    bool update = false;
    bool complete = false;

    _groupMemberState =
        _fieldStates[2] ? _groupMemberState : GroupMemberState.none;

    update = true;

    /// Email address status:
    /// doesn't match regex not a valid email yet
    /// _dropdownOptions.empty()
    ///   if _hasDroppeddown = newUser
    ///   else could have selected own email from keyboard - have to check if on API
    /// _dropdownOptions.contains(email) = a user
    /// _dropdownOptions.notEmpty email not complete
    ///

    if (_groupMemberState == GroupMemberState.none) {
      _fieldStates[2] = emailRegex.hasMatch(_email);

      if (_fieldStates[2]) {
        developer.log('Its a valid email ', name: '_dropdown');
        if (_dropdownOptions.contains(_email)) {
          _groupMemberState = GroupMemberState.resistered;
          developer.log(
              'dataComplete 316 start _groupMemberState changed to: ${_groupMemberState.toString()}');
          _fieldStates[0] = true;
          _fieldStates[1] = true;
          _dropdownOptions.clear();
          addMemberFromApi(email: _email);
          FocusManager.instance.primaryFocus?.unfocus();
        } else if (_dropdownOptions
            .where((em) => em.startsWith(_email))
            .toList()
            .isEmpty) {
          _groupMemberState = GroupMemberState.isNew;
          developer.log(
              'dataComplete 326 start _groupMemberState changed to: ${_groupMemberState.toString()}');
          _controller1.setNextAction(nextAction: TextInputAction.next);
          //  _textInputAction = TextInputAction.next;
          _fieldStates[0] = false;
          _fieldStates[1] = false;
        }
        update = true;
      } else {
        // update = _dropdownOptions.isNotEmpty;
      }
    }
    complete = _fieldStates[0] && _fieldStates[1] && _fieldStates[2];
    if (update) {
      if (_groupMemberState == GroupMemberState.isNew && complete) {
        _groupMemberState = GroupMemberState.complete;
        developer.log(
            'dataComplete 341 start _groupMemberState changed to: ${_groupMemberState.toString()}');
      }
      setState(() => ());
    }
    developer.log(
        'dataComplete end _groupMemberState: ${_groupMemberState.toString()}',
        name: '_state');
    return complete;
  }

  Future<bool> addMemberFromApi({required String email}) async {
    if (_groupMemberState == GroupMemberState.resistered) {
      _groupMemberState = GroupMemberState.added;
      _email = email;
      developer.log(
          'dataComplete 355 start _groupMemberState changed to: ${_groupMemberState.toString()}');
      //    await getUserByEmail(email)
      //        .then((newMember) {}); //widget.group.addMember(newMember));
      _fieldStates = [true, true, true];
      // _controller1.clear(); // Clear TextEditController
      return true;
    } else {
      return false;
    }
  }

  clearData({bool cancel = false}) {
    _groupMemberState = GroupMemberState.complete; // _addMember = false;
    developer.log(
        'dataComplete 374 start _groupMemberState changed to: ${_groupMemberState.toString()}');
    _controller1.clear;
    _controller2.clear;
    _fieldStates = [false, false, false];
    if (cancel && widget.onCancel != null) {
      widget.onCancel!(true);
    }
  }

  getDropdownItems(String query) async {
    _dropdownOptions.clear();
    if (query.isNotEmpty) {
      _dropdownOptions.addAll(await getApiOptions(value: query));
    }
  }
}
