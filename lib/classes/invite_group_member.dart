import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/other_models.dart';
import '/constants.dart';
import '/classes/classes.dart';
import '/services/services.dart';
import '/helpers/edit_helpers.dart';
import 'dart:developer' as developer;

/// InviteMember handles the adding of a new member to a group there are 2 options:
///   The invitee is already registered
///     InviteMember adds member to the Group class to be sent to API on confirmed update
///   The invitee is new
///     InviteMember sends an invitation email to the prospective member

class InviteMember extends StatefulWidget {
  final Function(GroupMember?)? onInvite;
  final Function(bool)? onCancel;
  final Function(bool)? onAddMemer;
  final Group group;
  // final GroupMember newMember;
  final bool addMember;
  final Color color;
  final double elevation;
  const InviteMember(
      {super.key,
      //     required this.newMember,
      required this.group,
      this.onInvite,
      this.onCancel,
      this.onAddMemer,
      this.addMember = false,
      this.color = Colors.white,
      this.elevation = 5});
  @override
  State<InviteMember> createState() => _InviteMemberState();
}

class _InviteMemberState extends State<InviteMember> {
  final List<String> _dropdownOptions = [];
  List<bool> _fieldStates = [false, false, false];
  late AutoCompleteAsyncController _controller1;
  late TextEditingController _controller2;
  late TextEditingController _controller3;
  late FocusNode _focusNode1;
  late FocusNode _focusNode2;
  GroupMember newMember = GroupMember(forename: '', surname: '');
  // TextInputAction _textInputAction = TextInputAction.done;
  late GroupMemberState _groupMemberState;

  @override
  void initState() {
    super.initState();
    _controller1 = AutoCompleteAsyncController();
    _controller2 = TextEditingController();
    _controller3 = TextEditingController();
    _focusNode1 = FocusNode();
    _focusNode2 = FocusNode();
    _groupMemberState = GroupMemberState.none;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller1.setFocus());
  }

  @override
  void dispose() {
    _controller2.dispose();
    _controller3.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  Widget suffix(List<bool> fieldStates) {
    if (!fieldStates[2]) {
      // return Icon(Icons.star_outline);
      return Padding(
        padding: EdgeInsetsGeometry.fromLTRB(0, 0, 5, 0),
        child: InkWell(
          radius: 33,
          onTap: () => cancelInvite(),
          child: Icon(
            Icons.cancel_outlined,
            size: 30,
            color: Colors.redAccent,
          ),
        ),
      );
    } else if ([GroupMemberState.complete, GroupMemberState.registered]
        .contains(_groupMemberState)) {
      return SizedBox(
        width: 82,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(0, 0, 5, 0),
              child: InkWell(
                radius: 33,
                onTap: () => invite(),
                child: Icon(Icons.check_circle_outline, size: 30),
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(0, 0, 5, 0),
              child: InkWell(
                radius: 33,
                onTap: () => cancelInvite(),
                child: Icon(
                  Icons.cancel_outlined,
                  size: 30,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return IconButton(
        onPressed: () => cancelInvite,
        icon: Icon(Icons.check_circle_outline),
      );
    }
  }

  invite() async {
    if (_groupMemberState == GroupMemberState.complete) {
      await sendInvitation();
      if (widget.onInvite != null) {
        widget.onInvite!(newMember);
      }
      setState(() => clearData(cancel: false));
    } else {
      if (widget.onInvite != null) {
        widget.onInvite!(newMember);
      }
    }
  }

  cancelInvite() {
    if (widget.onCancel != null) {
      widget.onCancel!(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (newMember.email.isEmpty) {
      try {
        _focusNode1.requestFocus();
      } catch (e) {
        developer.log('_focusNode1.requestFocus()', name: '_addState');
      }
    }
    return Card(
      elevation: widget.elevation,
      surfaceTintColor: widget.color,
      child: ListTile(
        title: Text(
          "Email address of person to invite",
          style: textStyle(context: context, color: Colors.black, size: 2),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(0, 20, 0, 0),
                          child: AutocompleteAsync(
                            controller: _controller1,
                            options: _dropdownOptions,
                            inputFormatters: [LowerCaseTextFormatter()],
                            searchLength: 1,
                            style: textStyle(
                                context: context, color: Colors.black, size: 2),
                            //       autofocus: true,
                            //   textInputAction: _textInputAction,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter users email address',
                              hintStyle: hintStyle(context: context),
                              labelText: 'Email address',
                              labelStyle: labelStyle(context: context),
                              //  prefix: Icon(Icons.cancel_outlined),
                              suffixIcon: suffix(_fieldStates),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onSelect: (chosen) async {
                              _groupMemberState = GroupMemberState.registered;
                              if (await addMemberFromApi(email: chosen)) {
                                newMember.email = chosen;
                                setState(() => _groupMemberState =
                                    GroupMemberState.registered);
                              }
                            },
                            onChange: (text) {
                              newMember.email = text;
                              dataComplete();
                            },
                            onUpdateOptionsRequest: (query) =>
                                getDropdownItems(query),
                          ),
                        ),
                      ),
                    ],
                  ),
                  //   if ([
                  //     GroupMemberState.isNew,
                  //     GroupMemberState.complete,
                  //     GroupMemberState.added
                  //   ].contains(_groupMemberState)) ...[
                  if (![GroupMemberState.none, GroupMemberState.registered]
                      .contains(_groupMemberState)) ...[
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            focusNode: _focusNode2,
                            //   initialValue: newMember.forename,
                            readOnly: _groupMemberState ==
                                GroupMemberState.registered,
                            keyboardType: TextInputType.name,
                            controller: _controller2,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter forename",
                              hintStyle: hintStyle(context: context),
                              labelText: 'Forename',
                              labelStyle: labelStyle(context: context, size: 3),
                              suffixIcon: Icon(_fieldStates[0]
                                  ? Icons.check_circle_outline
                                  : Icons.star_outline),
                            ),
                            style: textStyle(
                                context: context, size: 2, color: Colors.black),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (text) {
                              newMember.forename = text;
                              dataComplete();
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            autofocus: true,
                            keyboardType: TextInputType.name,
                            //  initialValue: newMember.surname ?? '',
                            readOnly: _groupMemberState ==
                                GroupMemberState.registered,
                            textInputAction: TextInputAction.done,
                            controller: _controller3,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter surname",
                              hintStyle: hintStyle(context: context),
                              labelText: 'Surname',
                              labelStyle: labelStyle(context: context, size: 3),
                              suffixIcon: Icon(_fieldStates[1]
                                  ? Icons.check_circle_outline
                                  : Icons.star_outline),
                            ),
                            style: textStyle(
                                context: context, size: 2, color: Colors.black),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (text) {
                              newMember.surname = text;
                              dataComplete();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            //  ],
            /*  Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, 20, 0, 0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    if ([GroupMemberState.complete, GroupMemberState.registered]
                        .contains(
                            _groupMemberState)) // (_addMember || _isRegistered)
                      ActionChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () async {
                          if (_groupMemberState == GroupMemberState.complete) {
                            await sendInvitation();
                            if (widget.onInvite != null) {
                              widget.onInvite!(newMember);
                            }
                            setState(() => clearData(cancel: false));
                          } else {
                            if (widget.onInvite != null) {
                              widget.onInvite!(newMember);
                            }
                          }
                        },
                        backgroundColor: Colors.blue,
                        avatar: Icon(
                          _groupMemberState == GroupMemberState.complete
                              ? Icons.person_add_alt_1_outlined
                              : Icons.how_to_reg_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          _groupMemberState == GroupMemberState.complete
                              ? "Send invitation"
                              : "Ok",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!(true);
                        }
                      },
                      //    onPressed: () => setState(() =>
                      //        clearData(cancel: true)), // widget.onAddLink!(index),
                      backgroundColor: Colors.blue,
                      avatar: const Icon(
                        Icons.person_off_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  bool dataComplete() {
    bool update = false;
    bool complete = false;

    _groupMemberState =
        _fieldStates[2] ? _groupMemberState : GroupMemberState.none;

    if (_groupMemberState == GroupMemberState.isNew) {
      update = _fieldStates[0] != newMember.forename.length > 2;
      _fieldStates[0] = newMember.forename.length > 2;
      update = update || (_fieldStates[1] != newMember.surname.length > 2);
      _fieldStates[1] = newMember.surname.length > 2;
    }
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
      _fieldStates[2] = emailRegex.hasMatch(newMember.email);

      if (_fieldStates[2]) {
        if (_dropdownOptions.contains(newMember.email)) {
          _groupMemberState = GroupMemberState.registered;
          _fieldStates[0] = true;
          _fieldStates[1] = true;
          _dropdownOptions.clear();
          addMemberFromApi(email: newMember.email);
          FocusManager.instance.primaryFocus?.unfocus();
        } else if (_dropdownOptions
            .where((em) => em.startsWith(newMember.email))
            .toList()
            .isEmpty) {
          _groupMemberState = GroupMemberState.isNew;
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
      }
      setState(() => ());
    }
    return complete;
  }

  Future<bool> addMemberFromApi({required String email}) async {
    if (_groupMemberState == GroupMemberState.registered) {
      _groupMemberState = GroupMemberState.added;
      await getUserByEmail(email).then((newMember) {
        if (widget.onInvite != null) {
          widget.onInvite!(newMember);
        }
      });
      _fieldStates = [true, true, true];
      _controller2.text = newMember.forename;
      _controller3.text = newMember.surname;
      return true;
    } else {
      return false;
    }
  }

  clearData({bool cancel = false}) {
    _groupMemberState = GroupMemberState.complete;
    _controller2.clear;
    _controller3.clear;
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

  Future<bool> sendInvitation() async {
    bool sent = false;
    newMember.phone =
        'Invited ${DateFormat("dd/MM/yy").format(DateTime.now())}';
    Map<String, dynamic> inviteeData = {
      "group_id": widget.group.id,
      "group_name": widget.group.name,
      "forename": newMember.forename,
      "surname": newMember.surname,
      "email": newMember.email,
      "phone": newMember.phone,
    };
    // widget.group.addMember(newMember);
    sent = await putIntroduced(inviteeData);
    // widget.addMember;
    _groupMemberState = GroupMemberState.added;
    return sent;
  }
}
