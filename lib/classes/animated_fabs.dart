// import 'package:universal_io/universal_io.dart';
import 'package:universal_io/universal_io.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '/models/models.dart';
import 'autocomplete_widget.dart';
import '/services/web_helper.dart';
import '/classes/other_classes.dart';
import '/helpers/edit_helpers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

//import '/classes/classes.dart';
//import ''
// Below example of implementing a voice recording widget
// https://ahmedghaly15.medium.com/flutter-deep-dive-implementing-seamless-audio-recording-4249ecbb04bb

class PlaceFinder extends StatefulWidget {
  final double width;
  final double height;
  final Function(LatLng)? onSelect;
  const PlaceFinder(
      {super.key, this.width = 20, this.height = 20, this.onSelect});

  @override
  State<PlaceFinder> createState() => _PlaceFinderState();
}

class _PlaceFinderState extends State<PlaceFinder> {
  final List<Place> _places = [];
  bool _expanded = false;
  double _width = 0;
  double _height = 0;
  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _height = widget.height;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      // color: Colors.blueAccent,
      width: _width,
      height: _height,
      decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(_height / 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black54,
                offset: const Offset(1, 3),
                blurRadius: 5,
                spreadRadius: 0)
          ]),
      curve: Curves.fastOutSlowIn,
      onEnd: () => setState(() => _expanded = _width > _height),
      child: _expanded
          ? Row(
              children: [
                SizedBox(
                  width: _width - _height,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                    child: AutocompletePlace(
                      options: _places,
                      optionsMaxHeight: 100,
                      searchLength: 3,
                      style: textStyle(context: context, color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: _width > _height ? OutlineInputBorder() : null,
                        hintText: 'Enter place name...',
                      ),
                      keyboardType: TextInputType.text,
                      onSelect: (chosen) =>
                          widget.onSelect!(LatLng(chosen.lat, chosen.lng)),
                      onChange: (text) => (debugPrint('onChange: $text')),
                      onUpdateOptionsRequest: (query) {
                        debugPrint('Query: $query');
                        getDropdownItems(query);
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                    child: IconButton(
                      onPressed: () {
                        setState(() => _width = _height);
                        _expanded = false;
                      },
                      icon: Icon(
                          _width > _height
                              ? Icons.search_off_outlined
                              : Icons.search_outlined,
                          size: _height / 2,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = false;
                      _width = MediaQuery.of(context).size.width - 40;
                    });
                  },
                  icon: Icon(Icons.search,
                      size: _height / 2, color: Colors.white),
                ),
              ),
            ),
    );
  }

  getDropdownItems(String query) async {
    _places.clear();
    _places.addAll(await getPlaces(value: query));
    setState(() {});
  }
}

class FloatingChecklist extends StatefulWidget {
  // final Function(int) onMenuTap;
  final Function(int, bool)? onCheck;
  final Function(bool)? onClose;

  final List<Map<String, bool>> choices;
  final double maxWidth;
  final double maxHeight;
  final double width;
  final double height;
  final Color backgoundColor;
  final IconData closedIcon;
  final IconData openIcon;
  final double closedIconSize;
  final Color closedIconColor;
  final double openIconSize;
  final Color openIconColor;

  const FloatingChecklist(
      {super.key,
      required this.choices,
      this.height = 56,
      this.maxHeight = 200,
      this.width = 56,
      this.maxWidth = 200,
      this.backgoundColor = Colors.blue,
      this.closedIcon = Icons.check_circle_outlined,
      this.closedIconSize = 30,
      this.closedIconColor = Colors.white,
      this.openIcon = Icons.settings,
      this.openIconSize = 30,
      this.openIconColor = Colors.white,
      this.onCheck,
      this.onClose});
  @override
  State<FloatingChecklist> createState() => _FloatingChecklistState();
}

class _FloatingChecklistState extends State<FloatingChecklist> {
  late double _width;
  late double _maxWidth;
  late double _height;
  late double _maxHeight;
  late bool _expanded;
  late List _choices;

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _maxWidth = widget.maxWidth;
    _height = widget.height;
    _maxHeight = widget.maxHeight;
    _choices = widget.choices;
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: _width,
      height: _height,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            color: Colors.black54,
            offset: const Offset(1, 3),
            blurRadius: 5,
            spreadRadius: 0)
      ], color: Colors.blue, borderRadius: BorderRadius.circular(30)),
      curve: Curves.fastOutSlowIn,
      onEnd: () => setState(() {
        _expanded = _width > widget.width && _height > widget.height;

        _height = _width == widget.width ? widget.height : _maxHeight;
      }),
      child: _expanded
          ? Row(children: [
              SizedBox(
                width: _width - widget.height,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                  child: Card(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          widget.choices.length,
                          (index) => Card(
                            child: CheckboxListTile(
                              value: _choices[index].values.toList()[0],
                              onChanged: (value) {
                                setState(() {
                                  _choices[index]
                                          [_choices[index].keys.toList()[0]] =
                                      value;
                                  if (widget.onCheck != null) {
                                    widget.onCheck!(index, value!);
                                  }
                                });
                              },
                              title: Text(_choices[index].keys.toList()[0],
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _width = widget.height;
                        _height = widget.height;
                        if (widget.onClose != null) {
                          widget.onClose!(true);
                        }
                      });
                      _expanded = false;
                    },
                    icon: Icon(
                        _width > widget.width
                            ? widget.closedIcon // Icons.settings_outlined
                            : widget.openIcon, //Icons.settings,
                        size: widget.openIconSize, //_height / 2,
                        color: widget.openIconColor // Colors.white),
                        ),
                  ),
                ),
              ),
            ])
          : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 4, 4, 0),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = false;
                      _width = _maxWidth;
                    });
                  },
                  icon: Icon(
                      _height == widget.height
                          ? widget.openIcon
                          : widget.closedIcon,
                      size: widget.closedIconSize,
                      color: widget.closedIconColor),
                ),
              ),
            ),
    );
  }
}

class FloatingTextEditController {
  _FloatingTextEditState? _floatingTextEditState;

  void _addState(_FloatingTextEditState floatingTextEditState) {
    _floatingTextEditState = floatingTextEditState;
  }

  bool get isAttached => _floatingTextEditState != null;

  void changeOpen(int id) {
    assert(isAttached, 'Controller must be attached to widget');
    try {
      _floatingTextEditState?.changeWidget(id);
    } catch (e) {
      String err = e.toString();
      debugPrint('Error loading image: $err');
    }
  }
}

class FloatingTextEdit extends StatefulWidget {
  final double maxWidth;
  final double maxHeight;
  final double width;
  final double height;
  final Color backgoundColor;
  final IconData closedIcon;
  final IconData openIcon;
  final double closedIconSize;
  final Color closedIconColor;
  final double openIconSize;
  final Color openIconColor;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String hint;
  final InputBorder? inputBorder;
  final Color fillColor;
  final Function(String)? onChange;
  final Function(String, String)? onClose;
  final Function(bool)? onOpen;
  final FloatingTextEditController? controller;
  const FloatingTextEdit({
    super.key,
    this.height = 56,
    this.maxHeight = 150,
    this.width = 56,
    this.maxWidth = 200,
    this.backgoundColor = Colors.blue,
    this.closedIcon = Icons.check_circle_outline,
    this.closedIconSize = 30,
    this.closedIconColor = Colors.white,
    this.openIcon = Icons.edit,
    this.openIconSize = 30,
    this.openIconColor = Colors.white,
    this.focusNode,
    this.suffix,
    this.hint = '',
    this.inputBorder,
    this.fillColor = Colors.white,
    this.keyboardType,
    this.onChange,
    this.onClose,
    this.onOpen,
    this.controller,
  });
  @override
  State<FloatingTextEdit> createState() => _FloatingTextEditState();
}

class _FloatingTextEditState extends State<FloatingTextEdit> {
  late double _width;
  late double _height;
  late bool _expanded;
  late TextEditingController _controller;
  late final AudioRecorder _recorder;
  final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final _picker = ImagePicker();
  // XFile? _image;
  String _audioPath = '';

  late bool _recording;

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _height = widget.height;
    _expanded = false;
    _recording = false;
    _controller = TextEditingController();
    _recorder = AudioRecorder();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    } else {
      debugPrint("widget.floatingTextEditController is null");
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  void changeWidget(int id) {
    if (id == 0) {
      if (_width > _height && id == 0) {
        setState(() {
          _width = _height;
          _expanded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      width: _width,
      height: _height,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
            color: Colors.black54,
            offset: const Offset(1, 3),
            blurRadius: 5,
            spreadRadius: 0)
      ], color: Colors.blue, borderRadius: BorderRadius.circular(_height / 2)),
      curve: Curves.fastOutSlowIn,
      onEnd: () => setState(() => _expanded = _width > _height),
      child: _expanded
          ? Row(
              children: [
                SizedBox(
                  width: _width - _height - 50,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 2, 5),
                    child: Stack(
                      children: [
                        TextField(
                          autofocus: true,
                          controller: _controller,
                          keyboardType: widget.keyboardType,
                          focusNode: widget.focusNode,
                          decoration: InputDecoration(
                            filled: true,
                            //  hint: Text(widget.hint),
                            border: widget.inputBorder,
                            fillColor: widget.fillColor,
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (text) => widget.onChange!(text),
                          onSubmitted: (text) {
                            //      debugPrint('$text submitted');
                          },
                        ),
                        Positioned(
                          right: -5,
                          child: IconButton(
                            onPressed: () async {
                              if (_recording) {
                                _audioPath = await _stop();
                              } else {
                                _record();
                              }
                              setState(() => (_recording = !_recording));
                            },
                            icon: Icon(
                                _recording
                                    ? Icons.mic_off_outlined
                                    : Icons.mic_outlined,
                                size: 30,
                                color: _recording ? Colors.red : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          try {
                            // was _image = await...
                            await _picker.pickImage(
                                source: ImageSource.camera, imageQuality: 10);
                            setState(() => ());
                          } catch (e) {
                            debugPrint('Image error: ${e.toString()}');
                          }
                        },
                        icon: Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(4, 4, 0, 0),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              if (widget.onClose != null) {
                                widget.onClose!(_controller.text, _audioPath);
                              }
                              _width = _height;
                            });
                            _play();
                            _expanded = false;
                          },
                          icon: Icon(
                            _width > _height
                                ? widget.openIcon
                                : widget.closedIcon,
                            size: _height / 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _expanded = false;
                      _width = MediaQuery.of(context).size.width - 40;
                      if (widget.onOpen != null) {
                        widget.onOpen!(true);
                      }
                    });
                  },
                  icon: Icon(widget.closedIcon,
                      size: _height / 2, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Future<bool> _record() async {
    if (await _recorder.hasPermission()) {
      String uuidString = Uuid().v7();
      try {
        String filePath =
            '${Setup().appDocumentDirectory}/sounds/$uuidString.wav';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav),
            path: filePath);
      } catch (e) {
        debugPrint('Error recorditng sound ${e.toString()}');
      }
      return true;
    } else {
      return false;
    }
  }

  Future<String> _stop() async {
    try {
      String path = '';
      path = await _recorder.stop() ?? "didn't stop";
      // debugPrint('Stop path: $path');
      return path;
    } catch (e) {
      debugPrint("Can't stop: ${e.toString()}");
      return '';
    }
  }

  Future<void> _play() async {
    if (await File(_audioPath).exists()) {
      DeviceFileSource source = DeviceFileSource(_audioPath);
      player.play(source);
    }
  }
}
