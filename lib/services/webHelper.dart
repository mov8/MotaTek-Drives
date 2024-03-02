import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Autocomplete API uses https://photo.komoot.io
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

/*
"{"features":[{"geometry":{"coordinates":[18.0710935,59.3251172],"type":"Point"},"type":"Feature","properties":{"osm_type":"R","o…"

 */