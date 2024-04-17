import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:drives/models.dart';

/// Autocomplete API uses https://photon.komoot.io
/// eg - https://photon.komoot.io/api/?q=staines
///
///

// Future<Map<String, dynamic>> getSuggestions(String value) async {

const List<String> settlementTypes = ['city', 'town', 'village', 'hamlet'];

Future<List<String>> getSuggestions(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value';
  List<String> suggestions = [''];
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      dynamic jResponse = json.decode(response.body);
      for (int i = 0; i < jResponse["features"].length; i++) {
        if (settlementTypes
            .contains(jResponse["features"][i]["properties"]["type"])) {
          suggestions.add(jResponse["features"][i]["properties"]["name"] +
              ' ' +
              (jResponse["features"][i]["properties"]["county"] ?? "") +
              ' ' +
              (jResponse["features"][i]["properties"]["state"] ?? ""));
        }
      }
    }
  }
  return suggestions;
}

Future<LatLng> getPosition(String value) async {
  String baseURL = 'https://photon.komoot.io/api/?q=$value&limit=1';
  LatLng pos = const LatLng(0.00, 0.00);
  var url = Uri.parse(baseURL);
  if (value.length > 2) {
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        dynamic jResponse = json.decode(response.body);
        pos = LatLng(jResponse["features"][0]["geometry"]["coordinates"][1],
            jResponse["features"][0]["geometry"]["coordinates"][0]);
      }
    } catch (e) {
      String error = e.toString();
      debugPrint('getPosition() error: $error');
    }
  }
  return pos;
}

class SearchLocation extends StatefulWidget {
  final Function onSelect;
  const SearchLocation({super.key, required this.onSelect});
  @override
  State<SearchLocation> createState() => _searchLocationState();
}

class _searchLocationState extends State<SearchLocation> {
  List<String> autoCompleteData = [];
  String waypoint = '';
  LatLng location = const LatLng(0.00, 0.00);
  late TextEditingController textEditingController;
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 45,
        width: MediaQuery.of(context).size.width - 50,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        // color: Colors.white,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
            child: Row(children: [
              const Expanded(
                flex: 1,
                child: Icon(Icons.search),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                  flex: 14,
                  child: Autocomplete(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      autoCompleteData =
                          await getSuggestions(textEditingValue.text);
                      setState(() {
                        waypoint = textEditingValue.text;
                      });
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return autoCompleteData.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      textEditingController = controller;
                      return TextFormField(
                          textCapitalization: TextCapitalization.characters,
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: const InputDecoration(
                              hintText: 'Search for place name'));
                    },
                    onSelected: (String selection) async {
                      clearSelections();
                      LatLng pos = await getPosition(selection);
                      widget.onSelect(pos);
                    },
                  )),
              const SizedBox(
                width: 10,
              ),
            ])));
  }

  void clearSelections() {
    textEditingController.text = '';
    autoCompleteData.clear();
  }
}

final apiUrl = 'http://10.101.1.155:5000/v1/user/register/';
final urlBase = 'http://10.101.1.155:5000/';

Future<String> postUser(User user) async {
  Map<String, dynamic> userMap = user.toMap();
  final http.Response response =
      await http.post(Uri.parse(urlBase + 'v1/user/register/'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
          },
          body: jsonEncode(userMap));
  if (response.statusCode == 201) {
    // 201 = Created
    debugPrint('User posted OK');
    Map<String, dynamic> map = jsonDecode(response.body);
    Setup().jwt = map['token'];
    return jsonEncode({'token': Setup().jwt, 'code': response.statusCode});
  } else {
    debugPrint('Failed to post user');
    return jsonEncode({'token': '', 'code': response.statusCode});
  }
}
