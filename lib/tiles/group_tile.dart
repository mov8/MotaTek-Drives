import 'package:drives/constants.dart';
import 'package:drives/helpers/edit_helpers.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/classes/classes.dart';
import 'dart:developer' as developer;

/// Groups is the class that organises driving groups it handles:
///
///   Adding a new group
///     Group name and owner added to API
///
///   Deleting an existing group
///     Group deleted from API all records in group_member removed from API
///
///   Editing a group name
///     Group name changed on API
///
///   Adding a new group member. Only the group owner can add a new member.
///   Members can remove themselves from a group
///   Group owners can remove a member
///     If the member is on the API then a new record is added to group_members
///     If not on API invitation email sent and details added to invited table on API from InviteMember class
///
///   Deleting an existing group member
///     The record in group_members is removed
///
///
/// PAINFUL 2-Day lesson on controllers and child widget state.
/// Controllers shouldn't be used for setting variables in the controlled widget if the controller
/// is handed to the parent in the case of an ExpansionTile. This is because if the parent has to
/// be recreated because the change affects it too, then the child will get redrawn, and the controller
/// will be linked to the new widgets state in the initState(). This gives rise to the error of trying to
/// call setState() on a widget that has already been disposed of. Lessons:
///   1 Controllers should be used to do something to children that doesn't need the parent to call setState()
///   2 Changing children's variables should be done through the child's constructor, which gets called when
///     the parent calls setState()

class GroupTileController {
  _GroupTileState? _groupTileState;

  void _addState(_GroupTileState groupTileState) {
    _groupTileState = groupTileState;
  }

  bool get isAttached => _groupTileState != null;

  void contract() {
    assert(isAttached, 'Controller must be attached to widget to clear');
    try {
      _groupTileState?.contract();
    } catch (e) {
      String err = e.toString();
      debugPrint('Error closing tile: $err');
    }
  }
}

class GroupTile extends StatefulWidget {
  final Group group;
  final bool expanded;
  final GroupActions actions;
  final Function(int, bool)? onEdit;
  final Function(String)? onDelete;
  final Function(int)? onAdd;
  final Function(int)? onSelect;
  final Function(int)? onCancel;
  final Function(int, bool, GroupTileController)? onExpand;

  final GroupTileController controller;

  final int index;
  const GroupTile({
    super.key,
    required this.index,
    required this.group,
    required this.controller,
    this.actions = GroupActions.none,
    this.expanded = false,
    this.onEdit,
    this.onDelete,
    this.onAdd,
    this.onSelect,
    this.onCancel,
    this.onExpand,
  });

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  bool _titleOk = false;
  bool _isNewGroup = false;
  bool _addMember = false;
  int _index = 0;
  Color cardColor = const Color.fromRGBO(155, 212, 240, 1);
  double cardElevation = 0;
  final List<String> dropdownOptions = [];
  int _memberCount = 0;
  late GroupMemberState _groupMemberState = GroupMemberState.none;
  final ExpansibleController _expansibleController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    widget.controller._addState(this);
    developer.log('initState _addState called', name: '_groupTile');
    _index = widget.index;
    _isNewGroup = widget.group.name.isEmpty;
  }

  @override
  void dispose() {
    developer.log('dispose called', name: '_groupTile');
    super.dispose();
  }

  addGroup() {
    setState(() => _isNewGroup = true);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(10),
        initiallyExpanded: widget.expanded,
        controller: _expansibleController,
        onExpansionChanged: (expanded) => expandChange(expanded),
        title: getTitle(),
        subtitle: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(5, 10, 0, 0),
          child: Text(
            '$_memberCount ${_memberCount == 1 ? 'member' : 'members'}',
            style:
                headlineStyle(context: context, size: 2, color: Colors.black),
          ),
        ),
        children: [
          ...List.generate(
            widget.group.groupMembers().length,
            (index) => Dismissible(
              key: UniqueKey(),
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
                      style: headlineStyle(
                          context: context, size: 2, color: Colors.black)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.group.groupMembers()[index].email,
                          style: textStyle(
                              context: context, size: 2, color: Colors.black)),
                      Text(widget.group.groupMembers()[index].phone,
                          style: textStyle(
                              context: context, color: Colors.black, size: 2))
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.actions == GroupActions.addMember) ...[
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

  addNewMember(member) {
    if (member != null && member.userId.isNotEmpty) {
      // && _groupMemberState == GroupMemberState.isNew) {
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
      _isNewGroup = false;
    });
  }

  onCancel() {
    if (widget.onDelete != null && _isNewGroup) {
      widget.onDelete!('');
    }
    if (widget.onCancel != null && !_isNewGroup) {
      widget.onCancel!(widget.index);
    }
    setState(() {
      _groupMemberState = GroupMemberState.none;
      _addMember = false;
    });
  }

  expandChange(bool expanded) {
    if (widget.onExpand != null) {
      widget.onExpand!(widget.index, expanded, widget.controller);
    }
  }

  contract() {
    _expansibleController.collapse();
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
      if (widget.onAdd != null) {}
    });
  }

  Widget titleSuffix() {
    if (_isNewGroup) {
      return Icon(_titleOk ? Icons.check_circle_outline : Icons.star_outline);
    } else {
      return widget.group.name.length < 3
          ? IconButton(onPressed: () => (), icon: Icon(Icons.cancel_outlined))
          : IconButton(
              onPressed: () => setState(() {
                    if (widget.onEdit != null) {
                      widget.onEdit!(_index, false);
                    }
                  }),
              icon: Icon(Icons.check));
    }
  }

  Widget getTitle() {
    _memberCount = widget.group.groupMembers().length;

    if ([GroupActions.editName, GroupActions.addGroup]
            .contains(widget.actions) &&
        !_addMember) {
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
        style: textStyle(context: context, size: 2, color: Colors.black),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: (text) {
          widget.group.name = text;
          if (_titleOk != text.length > 2) {
            setState(() => _titleOk = text.length > 2);
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
              style:
                  headlineStyle(context: context, size: 2, color: Colors.black),
            ),
          ),
        ],
      );
    } else {
      _memberCount = 0;
      return Text(
        'Add a new driving group',
        style: headlineStyle(context: context, size: 2, color: Colors.black),
      );
    }
  }

  String memberName({required GroupMember member}) {
    return ('${member.forename} ${member.surname}').trim();
  }
}
