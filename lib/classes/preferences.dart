import 'package:flutter/material.dart';

import '/classes/classes.dart';

class SetPreferences extends StatelessWidget {
  final TripsPreferences preferences;
  final ScrollController preferencesScrollController;
  const SetPreferences(
      {super.key,
      required this.preferences,
      required this.preferencesScrollController});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Icon(preferences.isLeft ? null : Icons.arrow_back_ios,
              color: Colors.white),
          SizedBox(
            width: MediaQuery.of(context).size.width - 60, //delta,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: preferencesScrollController,
              children: <Widget>[
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    checkColor: Colors.white,
                    title: const Text('Current location',
                        style: TextStyle(color: Colors.white)),
                    value: preferences.currentLocation,
                    onChanged: (value) => preferences.currentLocation = value!,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    hoverColor: Colors.white,
                    title: const Text('North West',
                        style: TextStyle(color: Colors.white)),
                    value: preferences.northWest,
                    onChanged: (value) => preferences.northWest = value!,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('North East',
                        style: TextStyle(color: Colors.white)),
                    value: preferences.northEast,
                    onChanged: (value) => preferences.northEast = value!,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    //  activeColor: Colors.white,
                    hoverColor: Colors.white,
                    title: const Text('South West',
                        style: TextStyle(color: Colors.white)),
                    value: preferences.southWest,
                    onChanged: (value) => preferences.southWest = value!,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: CheckboxListTile(
                    title: const Text('South East',
                        style: TextStyle(color: Colors.white)),
                    value: preferences.southEast,
                    onChanged: (value) => preferences.southEast = value!,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            preferences.isRight ? null : Icons.arrow_forward_ios,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
