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

class InviteMember extends StatefulWidget {
  final Function(bool)? onInvite;
  final Function(bool)? onCancel;
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
      this.addMember = false,
      this.color = Colors.white,
      this.elevation = 5});
  @override
  State<InviteMember> createState() => _InviteMemberState();
}

class _InviteMemberState extends State<InviteMember> {
  List<String> dropdownOptions = [];
  List<bool> fieldStates = [false, false, false];
  late AutoCompleteAsyncController _controller1;
  late TextEditingController _controller2;
  late TextEditingController _controller3;
  late FocusNode _focusNode1;
  late FocusNode _focusNode2;
  GroupMember newMember = GroupMember(forename: '', surname: '');
  //bool _hasDroppeddown = false;
  TextInputAction _textInputAction = TextInputAction.done;
  bool _addMember = false;
  bool _isNew = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _addMember = widget.addMember;
    _controller1 = AutoCompleteAsyncController();
    _controller2 = TextEditingController();
    _controller3 = TextEditingController();
    _focusNode1 = FocusNode();
    _focusNode2 = FocusNode();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller1.setFocus());
  }

  @override
  void dispose() {
    // _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (newMember.email.isEmpty) {
      _focusNode1.requestFocus();
    }
    return Card(
      elevation: widget.elevation,
      surfaceTintColor: widget.color,
      child: ListTile(
        title: Text(
          "Email address of person to invite",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_addMember) ...[
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 0),
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  // color: Colors.blueGrey,
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
                                options: dropdownOptions,
                                searchLength: 1,
                                textInputAction: _textInputAction,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter users email address',
                                  labelText: 'Email address',
                                  suffixIcon: Icon(fieldStates[2]
                                      ? Icons.check_circle_outline
                                      : Icons.star_outline),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onSelect: (chosen) =>
                                    addMemberFromApi(email: chosen),
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
                      if (_isNew) ...[
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                // autofocus: true,
                                focusNode: _focusNode2,
                                keyboardType: TextInputType.name,
                                controller: _controller2,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "Enter forename of invitee",
                                  labelText: 'Forename',
                                  suffixIcon: Icon(fieldStates[0]
                                      ? Icons.check_circle_outline
                                      : Icons.star_outline),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
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
                                textInputAction: TextInputAction.done,
                                controller: _controller3,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "Enter surname of invitee",
                                  labelText: 'Surname',
                                  suffixIcon: Icon(fieldStates[1]
                                      ? Icons.check_circle_outline
                                      : Icons.star_outline),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
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
              )
            ],
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, 20, 0, 0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    /*   if (!_addMember)
                      ActionChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => setState(() {
                          _addMember = true;
                          _isNew = false;
                          fieldStates = [false, false, false];
                          widget.newMember.email = '';
                        }), //addMember(add: true), // widget.onAddLink!(index),
                        backgroundColor: Colors.blue,
                        avatar: const Icon(
                          Icons.how_to_reg_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Invite new member",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ), */
                    if (dataComplete()) ...[
                      if (_addMember || _isRegistered)
                        ActionChip(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onPressed: () async {
                            if (_isNew) {
                              await sendInvitation();
                              if (widget.onInvite != null) {
                                widget.onInvite!(true);
                              }
                              setState(() => clearData(cancel: false));
                            } else {
                              if (widget.onInvite != null) {
                                widget.onInvite!(true);
                              }
                            }
                          },
                          backgroundColor: Colors.blue,
                          avatar: Icon(
                            _isNew
                                ? Icons.person_add_alt_1_outlined
                                : Icons.how_to_reg_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isNew ? "Send invitation" : "Ok",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                    ],
                    // if (_addMember)
                    ActionChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => setState(() =>
                          clearData(cancel: true)), // widget.onAddLink!(index),
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
          ],
        ),
      ),
    );
  }

  bool dataComplete() {
    bool update = false;
    if (fieldStates[0] != newMember.forename.length > 2) {
      fieldStates[0] = !fieldStates[0];
      update = true;
    }
    if (fieldStates[1] != newMember.surname.length > 2) {
      fieldStates[1] = !fieldStates[1];
      update = true;
    }

    /// Email address status:
    /// doesn't match regex not a valid email yet
    /// dropdownOptions.empty()
    ///   if _hasDroppeddown = newUser
    ///   else could have selected own email from keyboard - have to check if on API
    /// dropdownOptions.contains(email) = a user
    /// dropdownOptions.notEmpty email not complete
    ///

    fieldStates[2] = emailRegex.hasMatch(newMember.email);

    if (fieldStates[2]) {
      developer.log('Its a valid email ', name: '_dropdown');
      _isRegistered = dropdownOptions.isNotEmpty &&
          dropdownOptions.contains(newMember.email);
      if (_isRegistered) {
        dropdownOptions.clear;
        fieldStates[0] = true;
        fieldStates[1] = true;
        FocusManager.instance.primaryFocus?.unfocus();
      } else if (!_isNew) {
        _isNew = true;
        // _focusNode2.requestFocus();
        _textInputAction = TextInputAction.next;
        fieldStates[0] = false;
        fieldStates[1] = false;
      }
      dropdownOptions.clear();

      /// Remove keyboard

      update = true;
    } else {
      _isNew = false;
      update = dropdownOptions.isNotEmpty;
    }
    if (update) {
      if (_isNew && newMember.forename.isEmpty) {
        developer.log('Updating _focusNode2', name: '_dropdown');
        //    _focusNode2.requestFocus();
      }
      setState(() => ());
    }
    return fieldStates[0] && fieldStates[1] && fieldStates[2];
  }

  Future<bool> addMemberFromApi({required String email}) async {
    newMember = await getUserByEmail(email);
    widget.group.addMember(newMember);
    fieldStates = [true, true, true];
    _isRegistered = true;
    _controller1.clear();
    widget.onInvite!(true);
    return true;
  }

  clearData({bool cancel = false}) {
    _addMember = false;
    _controller1.clear;
    _controller2.clear;
    _controller3.clear;
    fieldStates = [false, false, false];
    if (cancel && widget.onCancel != null) {
      widget.onCancel!(true);
    }
  }

  getDropdownItems(String query) async {
    dropdownOptions.clear();
    if (query.isNotEmpty) {
      dropdownOptions.addAll(await getApiOptions(value: query));
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
    widget.group.addMember(newMember);
    sent = await putIntroduced(inviteeData);
    return sent;
  }
}
