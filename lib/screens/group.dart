import 'package:drives/tiles/group_member_tile.dart';
import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class GroupForm extends StatefulWidget {
  // var setup;

  const GroupForm({super.key, setup});

  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  int group = 0;
  late Future<bool> dataloaded;
  late FocusNode fn1;

  late GroupMember newMember;
  late Group newGroup;
  List<GroupMember> groupMembers = [];
  List<Group> groups = [];

  RegExp emailRegex = RegExp(r'[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  final _formKey = GlobalKey<FormState>();
  String groupName = 'Driving Group';
  bool edited = false;
  int groupIndex = 0;
  double _emailSizedBoxHeight = 70;
  bool _validate = false;
  String _validateMessage = '';
  String testString = '';
  bool addingMember = false;
  bool addingGroup = false;
  bool editingGroup = false;

  List<GroupMember> allMembers = [];

  @override
  void initState() {
    super.initState();
    fn1 = FocusNode();
    // dataloaded = dataFromDatabase();
    dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    fn1.dispose();
    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    groups = await loadGroups();
    groupMembers = await loadGroupMembers();
    if (groups.isEmpty) {
      groups.add(Group(id: '', name: '', edited: true));
      groupIndex = 0;
      edited = true;
    }
    return true;
  }

  Future<bool> dataFromWeb() async {
    groups = await getGroups();
    if (groups.isNotEmpty) {
      for (Group group in groups) {
        for (GroupMember member in group.groupMembers()) {
          member.selected = true;
          allMembers.add(member);
        }
      }
      allMembers.sort((a, b) => '${a.forename} ${a.surname}'
          .toLowerCase()
          .compareTo('${b.forename} ${b.surname}'.toLowerCase()));

      groupIndex = 0;
      membersOfGroup(groups[groupIndex]);
    } else {
      groups.add(Group(id: '', name: '', edited: true));
      groupIndex = 0;
      edited = true;
    }
    return true;
  }

  membersOfGroup(Group group) {
    for (GroupMember member in allMembers) {
      member.selected = group.groupMembers().contains(member);
    }
  }

  addMembersToGroup(Group group) {
    List<GroupMember> members = [
      for (GroupMember member in allMembers)
        if (member.selected) member
    ];
    group.setGroupMembers(members);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text('MotaTek groups',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
              child: Text(
                  groups.isNotEmpty
                      ? '${groups[groupIndex].name}${groups[groupIndex].edited ? '*' : ''}'
                      : 'Create groups',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ))),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<bool>(
        future: dataloaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return portraitView();
          } else {
            return const SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator()));
          }

          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView() {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: DropdownButtonFormField<String>(
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Group name',
            ),
            value: groups[groupIndex].name,
            items: groups
                .map((item) => DropdownMenuItem<String>(
                      value: item.name,
                      child: Text(item.name,
                          style: Theme.of(context).textTheme.titleLarge!),
                    ))
                .toList(),
            onChanged: (item) => {
              setState(() {
                groupIndex =
                    groups.indexWhere((group) => group.name == item.toString());
                membersOfGroup(groups[groupIndex]);
              })
            },
          )),
      if (addingMember) ...[
        handleNewMember(),
      ],
      if (addingGroup) ...[
        handleNewGroup(),
      ],
      if (editingGroup) ...[
        handleEditGroup(),
      ],
      if (allMembers.isNotEmpty) ...[
        Expanded(
          child: ListView.builder(
            itemCount: allMembers.length,
            itemBuilder: (context, index) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: GroupMemberTile(
                groupMember: allMembers[index],
                index: index,
                onSelect: onSelect,
              ),
            ),
          ),
        )
      ],
      Align(
        alignment: Alignment.bottomLeft,
        child: _handleChips(),
      )
    ]);
  }

  Widget handleNewGroup() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SizedBox(
          height: _emailSizedBoxHeight,
          child: TextFormField(
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              _emailSizedBoxHeight = 70;
              if (!_validate) {
                return null;
              }
              if (_validateMessage.isNotEmpty) {
                _emailSizedBoxHeight = 100;
                return (_validateMessage);
              }
              if (value!.isEmpty) {
                _emailSizedBoxHeight = 100;
                return ("Group name can't be empty");
              }
              return null;
            },
            onFieldSubmitted: (val) => setState(() {
              newGroup.name = val;

              if (newGroup.name.isNotEmpty) {
                groups.add(newGroup);
                groupIndex = groups.length - 1;
                groupName = groups[groupIndex].name;
              }
            }),
            autofocus: true,
            focusNode: fn1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter the name of the new group",
                labelText: "New group's name",
                suffix: IconButton(
                    onPressed: () async {
                      if (_validate) {
                        setState(() {
                          _validate = false;
                          addingGroup = false;
                        });
                      } else {
                        _validate = true;
                        for (Group group in groups) {
                          if (group.name == newGroup.name) {
                            _validateMessage =
                                'You already have a group called ${newGroup.name}';
                            break;
                          }
                        }

                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            if (newGroup.name.isNotEmpty) {
                              groups.add(newGroup);
                              groupIndex = groups.length - 1;
                              groups[groupIndex].edited = true;
                              membersOfGroup(groups[groupIndex]);
                              addingGroup = false;
                            } else {
                              _validateMessage =
                                  'You must enter the new group name';
                              _formKey.currentState!.validate();
                            }
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    },
                    icon: Icon(_validate
                        ? Icons.cancel_outlined
                        : Icons.add_circle_outline))),
            textAlign: TextAlign.left,
            initialValue: newGroup.name,
            onChanged: (text) {
              if (_validate) {
                _validate = false;
                _formKey.currentState!.validate();
              }
              newGroup.name = text;
            },
          ),
        ),
      ),
    );
  }

  Widget handleEditGroup() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SizedBox(
          height: _emailSizedBoxHeight,
          child: TextFormField(
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              _emailSizedBoxHeight = 70;
              if (!_validate) {
                return null;
              }
              if (_validateMessage.isNotEmpty) {
                _emailSizedBoxHeight = 100;
                return (_validateMessage);
              }
              if (value!.isEmpty) {
                _emailSizedBoxHeight = 100;
                return ("Group name can't be empty");
              }
              return null;
            },
            onFieldSubmitted: (val) => setState(() {
              groupName = val;
              groups[groupIndex].name = val;
            }),
            autofocus: true,
            focusNode: fn1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter the new name for ${groups[groupIndex].name}",
                labelText: "${groups[groupIndex].name}'s new name",
                suffix: IconButton(
                    onPressed: () async {
                      if (_validate) {
                        setState(() {
                          _validate = false;
                          addingGroup = false;
                        });
                      } else {
                        _validate = true;
                        for (int i = 0; i < groups.length; i++) {
                          if (groups[i].name == groups[groupIndex].name &&
                              i != groupIndex) {
                            _validateMessage =
                                'You already have a group called ${groups[groupIndex].name}';
                            break;
                          }
                        }

                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            if (groups[groupIndex].name.isNotEmpty) {
                              groups[groupIndex].edited = true;
                              editingGroup = false;
                            } else {
                              _validateMessage =
                                  'You must enter the new group name';
                              _formKey.currentState!.validate();
                            }
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    },
                    icon: Icon(_validate
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline))),
            textAlign: TextAlign.left,
            initialValue: groups[groupIndex].name,
            onChanged: (text) {
              if (_validate) {
                _validate = false;
                _formKey.currentState!.validate();
              }
              groups[groupIndex].name = text;
            },
          ),
        ),
      ),
    );
  }

  Widget handleNewMember() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: SizedBox(
          height: _emailSizedBoxHeight,
          child: TextFormField(
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              _emailSizedBoxHeight = 70;
              if (!_validate) {
                return null;
              }
              if (_validateMessage.isNotEmpty) {
                _emailSizedBoxHeight = 100;
                return (_validateMessage);
              }
              if (value!.isEmpty) {
                _emailSizedBoxHeight = 100;
                return ("email can't be empty");
              }
              if (!emailRegex.hasMatch(value)) {
                _emailSizedBoxHeight = 110;
                return ('not a valid email address');
              }
              return null;
            },
            onFieldSubmitted: (val) => setState(() {
              newMember.email = val;

              if (groups[groupIndex].name.isNotEmpty) {
                groupName = groups[groupIndex].name;
              }
            }),
            autofocus: true,
            focusNode: fn1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: "Enter member's email address",
                labelText: "New member's email",
                suffix: IconButton(
                    onPressed: () async {
                      if (_validate) {
                        setState(() {
                          _validate = false;
                          addingMember = false;
                        });
                      } else {
                        _validate = true;
                        for (GroupMember member
                            in groups[groupIndex].groupMembers()) {
                          if (member.email == newMember.email) {
                            _validateMessage =
                                '${member.forename} ${member.surname} is already in ${groups[groupIndex].name}';
                            break;
                          }
                        }

                        if (_formKey.currentState!.validate()) {
                          newMember = await getUserByEmail(newMember.email);
                          setState(() {
                            if (newMember.forename.isNotEmpty &&
                                newMember.surname.isNotEmpty) {
                              newMember.selected = true;
                              newMember.groupId = groups[groupIndex].id;
                              groups[groupIndex].addMember(newMember);
                              groups[groupIndex].edited = true;
                              allMembers.add(newMember);
                              addingMember = false;
                            } else {
                              _validateMessage = 'User email not found';
                              _formKey.currentState!.validate();
                            }
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    },
                    icon: Icon(
                        _validate ? Icons.cancel_outlined : Icons.search))),
            textAlign: TextAlign.left,
            initialValue: newMember.email,
            onChanged: (text) {
              if (_validate) {
                _validate = false;
                _formKey.currentState!.validate();
              }
              newMember.email = text;
            },
          ),
        ),
      ),
    );
  }

  Widget _handleChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 10,
        children: [
          if (addingMember || addingGroup || editingGroup) ...[
            ActionChip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () => setState(() {
                addingMember = false;
                addingGroup = false;
                editingGroup = false;
              }),
              backgroundColor: Colors.blue,
              avatar: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              label: const Text('Back',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ] else if (groupIndex >= 0) ...[
            if (groups[groupIndex].name.isNotEmpty) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => setState(
                  () {
                    fn1.requestFocus();
                    addingMember = true;
                    _validate = false;
                    _validateMessage = '';
                    _emailSizedBoxHeight = 70;
                    newMember = GroupMember(forename: '', surname: '');
                  },
                ),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.group_add,
                  color: Colors.white,
                ),
                label: const Text('New Member',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => setState(() {
                  fn1.requestFocus();
                  addingGroup = true;
                  _validate = false;
                  _validateMessage = '';
                  _emailSizedBoxHeight = 70;
                  newGroup = Group(name: '');
                }),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.groups,
                  color: Colors.white,
                ),
                label: const Text('New Group',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              ActionChip(
                onPressed: () => setState(() {
                  editingGroup = true;
                  _validateMessage = '';
                  _emailSizedBoxHeight = 70;
                  fn1.requestFocus();
                }),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                avatar: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                label: const Text('Edit Name',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () async {
                  for (Group group in groups) {
                    if (group.edited) {
                      await putGroup(groups[groupIndex]);
                    }
                  }
                },
                backgroundColor: Colors.blue,
                avatar: const Icon(Icons.save, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
            if (group > 1 && groups[groupIndex].name.isNotEmpty) ...[
              ActionChip(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () => (),
                backgroundColor: Colors.blue,
                avatar: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
                label: const Text('Delete Group',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void onDelete(int index) {
    return;
  }

  void onSelect(int index) {
    int idx = groups[groupIndex].groupMembers().indexOf(allMembers[index]);
    if (allMembers[index].selected) {
      if (idx >= 0) {
        groups[groupIndex].removeMember(idx);
        groups[groupIndex].edited = true;
      }
    } else if (idx < 0) {
      groups[groupIndex].addMember(allMembers[index]);
      groups[groupIndex].edited = true;
    }
    return;
  }
}
