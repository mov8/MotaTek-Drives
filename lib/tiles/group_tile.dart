import 'package:drives/constants.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'dart:developer' as developer;

/// Groups is the class that organises driving groups it handles:
///
///   Adding a new group
///     Group name and owner added to API
///
///   Deleteting an existing group
///     Group deleted from API all records in group_member removed from API
///
///   Editing a group name
///     Group name changed on API
///
///   Adding a new group member. Only the group owner can add a new member.
///   Members can remove themselves from a group
///   Group owners can remove a member
///     If the member is on the API then a new record is added to group_mambers
///     If not on API invitation email sent and details added to invited table on API from InviteMember class
///
///   Deleteing an existing group mamber
///     The record in group_members is removed

class GroupTileController {
  _GroupTileState? _groupTileState;

  void _addState(_GroupTileState groupTileState) {
    developer.log('_addState called', name: '_addState');
    _groupTileState = groupTileState;
  }

  bool get isAttached => _groupTileState != null;

  void newGroup() {
    developer.log('newGroup called', name: '_addState');
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _groupTileState?.addGroup();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void newMember() {
    developer.log('newGroup called', name: '_addState');
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _groupTileState?.addMember();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }

  void editGroupName() {
    developer.log('newGroup called', name: '_addState');
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _groupTileState?.editGroupName();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error clearing AutoComplete: $err');
    }
  }
}

class GroupTile extends StatefulWidget {
  final Group group;
  final bool expanded;
  final Function(int, bool)? onEdit;
  final Function(String)? onDelete;
  final Function(int)? onAdd;
  final Function(int)? onSelect;
  final Function(int, bool)? onExpand;
  final GroupTileController controller;

  final int index;
  const GroupTile({
    super.key,
    required this.index,
    required this.group,
    required this.controller,
    this.expanded = false,
    this.onEdit,
    this.onDelete,
    this.onAdd,
    this.onSelect,
    this.onExpand,
  });

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  bool _isEditing = false;
  final bool _showChip = false;
  bool _titleOk = false;
  bool _isNewGroup = false;
  bool _addMember = false;
  int _index = 0;
  Color cardColor = const Color.fromRGBO(155, 212, 240, 1);
  double cardElevation = 0;
  final List<String> dropdownOptions = [];
  int _memberCount = 0;
  late GroupMemberState _groupMemberState = GroupMemberState.none;

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    developer.log('initState _addState called', name: '_addState');
    _isEditing = widget.group.name.isEmpty;
    _index = widget.index;
    _isNewGroup = widget.group.name.isEmpty;
//    _groupMemberState = GroupMemberState.none;
    developer.log('@initState _groupMemberState: ${_groupMemberState.name}',
        name: '_GroupMemberState');
    developer.log('InitState() _isNewGroup: $_isNewGroup', name: '_newGroup');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //  addMember();
    developer.log('@build _groupMemberState: ${_groupMemberState.name}',
        name: '_GroupMemberState');
    return Card(
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(10),
        initiallyExpanded: widget.expanded,
        onExpansionChanged: (expanded) => expandChange(expanded),
        title: getTitle(),
        subtitle: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(5, 10, 0, 0),
          child: Text(
            '$_memberCount ${_memberCount == 1 ? 'member' : 'members'}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          ...List.generate(
            widget.group.groupMembers().length,
            (index) => Dismissible(
              key: UniqueKey(), // Key('gmlt$index'),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                if (widget.group
                        .groupMembers()[index]
                        .phone
                        .startsWith('Invited') &&
                    widget.onDelete != null) {
                  widget.onDelete!(widget.group.groupMembers()[index].email);
                } else {
                  widget.group.edited = true;
                }

                setState(() => widget.group.removeMember(index));
              },
              background: Container(color: Colors.blueGrey),
              child: Card(
                borderOnForeground: true,
                surfaceTintColor: cardColor,
                elevation: cardElevation,
                child: ListTile(
                  leading: widget.group
                          .groupMembers()[index]
                          .phone
                          .contains('Invited')
                      ? Icon(Icons.person_add_alt_1_outlined, size: 30)
                      : Icon(Icons.how_to_reg_outlined, size: 30),
                  title: Text(
                    memberName(member: widget.group.groupMembers()[index]),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.group.groupMembers()[index].email,
                          style: TextStyle(fontSize: 20)),
                      Text(widget.group.groupMembers()[index].phone,
                          style: TextStyle(fontSize: 20))
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_addMember)
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(5, 30, 5, 10),
              child: Wrap(spacing: 10, children: [handleChips()]),
            ),
          if (_groupMemberState == GroupMemberState.isNew) ...[
            InviteMember(
              group: widget.group,
              color: cardColor,
              addMember: true,
              elevation: cardElevation,
              onInvite: (member) => addNewMember(member),
              onCancel: (value) => onCancel(),
            )
          ],
        ],
      ),
    );
  }

  //addMember() {
  //  widget.group.groupMembers().add(GroupMember(forename: '', surname: ''));
  //}

  /// The GroupTile displays a list of all the members in the group in a series of cards.
  ///
  /// addMember() automaticall adds a new empty member to the list of members so the user can invite
  /// a new member. It first checks to make sure one hasn't yet been added.
  /// Initially the card only show the add button. When the button is clicked the details editors are
  /// exposed and the buttons change to Invite (if validated) or cancel
  /// Once the invitation has been sent a new empty member is added to the Group.members

  addGroup() {
    setState(() => _isNewGroup = true);
  }

  addNewMember(member) {
    developer.log(
        '@addNewMember start _groupMemberState: ${_groupMemberState.name}',
        name: '_GroupMemberState');
    if (member != null && _groupMemberState == GroupMemberState.isNew) {
      developer.log('addMember() ${member.email}', name: '_member');
      widget.group.addMember(member);
      if (widget.onAdd != null) {
        widget.onAdd!(1);
      }
      _groupMemberState = GroupMemberState.none;
      widget.group.edited = true;
    }
    setState(() {
      _groupMemberState = GroupMemberState.none;
      _addMember = false;
      _isEditing = false;
      _isNewGroup = false;
    });
    developer.log(
        '@addNewMember end _groupMemberState: ${_groupMemberState.name}',
        name: '_GroupMemberState');
  }

  onCancel() {
    developer.log('onCancel called in groupTile', name: '_dropdown');
    if (widget.onDelete != null && _isNewGroup) {
      widget.onDelete!('');
    }

    setState(() {
      developer.log('@onCancel _groupMemberState: ${_groupMemberState.name}',
          name: '_GroupMemberState');
      _groupMemberState = GroupMemberState.none;
      _addMember = false;
    });
  }

  expandChange(bool expanded) {
    if (widget.onExpand != null) {
      widget.onExpand!(_index, expanded);
    }
  }

  Widget handleChips() {
    developer.log('hancleChips _newGroup: $_isNewGroup', name: '_newGroup');
    if (_showChip) {
      return ActionChip(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () => setState(
            () => ()), //_addMember = true), // widget.onAddLink!(index),
        backgroundColor: Colors.blue,
        avatar: const Icon(
          Icons.cancel_outlined,
          color: Colors.white,
        ),
        label: const Text(
          "Cancel",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }
    if (!_addMember) {
      developer.log('_isNewGroup is true should show buttons',
          name: '_newGroup');
      return Wrap(
        spacing: 5,
        children: [
          if (widget.group.name.length < 2)
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () =>
                  widget.onDelete!(''), // widget.onAddLink!(index),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.group_off_outlined,
                color: Colors.white,
              ),
              label: const Text(
                "Cancel",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          /*   if (widget.group.name.length > 2) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => setState(() {
                _addMember = true;
                _groupMemberState = GroupMemberState.isNew;
                developer.log(
                    '@AddMember action chip _groupMemberState: ${_groupMemberState.name}',
                    name: '_GroupMemberState');
                if (widget.onAdd != null) {
                  //       widget.onAdd!(1);
                }
                // _isUpdated = true;
              }),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.groups_outlined,
                color: Colors.white,
              ),
              label: const Text(
                "Add member",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            /* if (widget.group.edited)
              ActionChip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  if (widget.onEdit != null) {
                    widget.onEdit!(widget.index, true);
                  }
                },
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.groups_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  "Save changes",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            */
          ] */
        ],
      );
    }
    return SizedBox();
  }

  void notifyParent({int index = 0}) {
    if (widget.onEdit != null) {
      widget.onEdit!(widget.index, true);
    }
  }

  void addMember() {
    setState(() {
      _addMember = true;
      _groupMemberState = GroupMemberState.isNew;
      developer.log(
          '@AddMember action chip _groupMemberState: ${_groupMemberState.name}',
          name: '_GroupMemberState');
      if (widget.onAdd != null) {
        //       widget.onAdd!(1);
      }
      // _isUpdated = true;
    });
  }

  Widget titleSuffix() {
    if (_isNewGroup) {
      return Icon(_titleOk ? Icons.check_circle_outline : Icons.star_outline);
    } else {
      return widget.group.name.length < 3
          ? IconButton(
              onPressed: () => setState(() => _isEditing = false),
              icon: Icon(Icons.cancel_outlined))
          : IconButton(
              onPressed: () => setState(() {
                    _isEditing = false;
                    if (widget.onEdit != null) {
                      widget.onEdit!(_index, false);
                    }
                  }),
              icon: Icon(Icons.check));
    }
  }

  Widget getTitle() {
    _memberCount = widget.group.groupMembers().length;

    if ((_isEditing || _isNewGroup) && !_addMember) {
      return TextFormField(
        autofocus: true,
        initialValue: widget.group.name,
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Enter the group's name",
          labelText: 'Group name',
          suffixIcon: titleSuffix(),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (text) {
          widget.group.name = text;
          if (_titleOk != text.length > 2) {
            setState(() => _titleOk = text.length > 2);
            //   setState(() => _showChip = true);
          }
        },
      );
    } else if (widget.group.name.isNotEmpty) {
      return Row(
        children: [
          Expanded(
            flex: 10,
            child: Text(
              widget.group.name,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          /* Expanded(
            flex: 2,
            child: IconButton(
              iconSize: 30,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              color: Colors.black,
              onPressed: () => setState(() => _isEditing = true),
            ),
          ), */
        ],
      );
    } else {
      _memberCount = 0;
      return Text('Add a new driving group',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
    }
  }

  String memberName({required GroupMember member}) {
    return ('${member.forename} ${member.surname}').trim();
  }

  void editGroupName() {
    setState(() => _isEditing = true);
  }
}
