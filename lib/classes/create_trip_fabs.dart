import 'dart:math';
import '../classes/classes.dart' hide Position;
import '../models/models.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';
import 'dart:developer' as developer;
import 'package:maplibre_gl/maplibre_gl.dart';

class HandleCTFabs extends StatelessWidget {
  final double _width = 50;
  final double _height = 56.0;
  final MapLibreMapController controller;
  final FloatingTextEditController? teController;
  final Function(bool)? update;
  const HandleCTFabs(
      {super.key, required this.controller, this.update, this.teController});

  @override
  Widget build(BuildContext context) {
    bool osmIncludingChange = false;
    developer.log('Building HandleCTFabs', name: '_fabs_');
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (CurrentTripItem().tripState == TripState.following)
          const SizedBox(height: 120),
        PlaceFinder(
          height: _height,
          width: _width,
          onSelect: (position) => controller.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        FloatingChecklist(
          choices: [
            {'Avoid motorways': Setup().avoidMotorways},
            {'Avoid main roads': Setup().avoidAroads},
            {'Avoid ferries': Setup().avoidFerries},
            {'Avoid toll roads': Setup().avoidTollRoads},
            {'Show pubs and bars': Setup().osmPubs},
            {'Show cafes and restaurants': Setup().osmRestaurants},
            {'Show fuel and charging stations': Setup().osmFuel},
            {'Show toilets': Setup().osmToilets},
            {'Show ATMs': Setup().osmAtms},
            {'Show historic sites': Setup().osmHistorical}
          ],
          maxWidth: MediaQuery.of(context).size.width - 40,
          onCheck: (index, value) {
            switch (index) {
              case 0:
                Setup().avoidMotorways = value;
                break;
              case 1:
                Setup().avoidAroads = value;
                break;
              case 2:
                Setup().avoidFerries = value;
                break;
              case 3:
                Setup().avoidTollRoads = value;
                break;
              case 4:
                Setup().osmPubs = value;
                break;
              case 5:
                Setup().osmRestaurants = value;
                break;
              case 6:
                Setup().osmFuel = value;
                break;
              case 7:
                Setup().osmToilets = value;
                break;
              case 8:
                Setup().osmAtms = value;
                break;
              case 9:
                Setup().osmHistorical = value;
                break;
            }
            osmIncludingChange = true;
          },
          onClose: (_) async {
            if (osmIncludingChange) {
              osmIncludingChange = false;
            }
          },
        ),
        const SizedBox(height: 10),
        if ([TripState.tracking, TripState.following]
            .contains(CurrentTripItem().tripState)) ...[
          FloatingTextEdit(
            key: Key('ftepoi'),
            focusNode: FocusNode(),
            keyboardType: TextInputType.name,
            controller: teController,
            closedIcon: Icons.add_location_alt_outlined,
            openIcon: Icons.add_task_outlined,
            onOpen: (_) => CurrentTripItem().saveState(),
            onClose: (description, audio) =>
                CurrentTripItem().pointsOfInterest.add(
                      PointOfInterest(
                        point: CurrentTripItem().tripValues.position,
                        description: description,
                        sounds: audio,
                      ),
                    ),
            fillColor: Colors.white,
            inputBorder: _width > _height ? OutlineInputBorder() : null,
            hint: 'Description to edit later...',
            suffix: IconButton(onPressed: (() => ()), icon: Icon(Icons.mic)),
          ),
          if (CurrentTripItem().isGoodRoad) ...[
            const SizedBox(height: 10),
            FloatingTextEdit(
              key: Key('ftegr'),
              focusNode: FocusNode(),
              keyboardType: TextInputType.name,
              controller: teController,
              closedIcon: Icons.remove_road,
              openIcon: Icons.add_task_outlined,
              onOpen: (_) => CurrentTripItem().saveState(),
              onClose: (description, audio) =>
                  updateRouteType(description: description, sound: audio),
              fillColor: Colors.white,
              inputBorder: _width > _height ? OutlineInputBorder() : null,
              hint: 'Description to edit later...',
              suffix: IconButton(
                onPressed: (() => (update!(true))),
                icon: Icon(
                  Icons.mic,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
          if (!CurrentTripItem().isGoodRoad) ...[
            const SizedBox(height: 10),
            FloatingActionButton(
              onPressed: () => updateRouteType(),
              heroTag: 'goodRoadOn',
              backgroundColor: Colors.blue,
              shape: const CircleBorder(),
              child: Icon(
                Icons.add_road,
                color: CurrentTripItem().isTracking
                    ? CurrentTripItem().tripValues.autoCentre
                        ? Colors.white
                        : Colors.grey
                    : Colors.white,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ],
        FloatingActionButton(
          onPressed: () => updatePosition(),
          heroTag: 'mapCentre',
          backgroundColor: Colors.blue,
          shape: const CircleBorder(),
          child: Icon(
            Icons.my_location,
            color: CurrentTripItem().isTracking
                ? CurrentTripItem().tripValues.autoCentre
                    ? Colors.white
                    : Colors.grey
                : Colors.white,
          ),
        ),
      ],
    );
  }

  fteUpdate({String description = '', String audio = ''}) {
    CurrentTripItem().pointsOfInterest.add(PointOfInterest(
        point: CurrentTripItem().tripValues.position,
        description: description,
        sounds: audio));
  }

  updatePosition() async {
    CurrentTripItem().tripValues.autoCentre =
        !CurrentTripItem().tripValues.autoCentre;
    Position position = await Geolocator.getCurrentPosition();
    Point point = Point(position.longitude, position.latitude);
    if (CurrentTripItem().tripValues.autoCentre) {
      if (CurrentTripItem().tripState != TripState.following) {
        CurrentTripItem().tripValues.position = point;
      }
    }
    controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  /// updateRouteType()
  /// if ! CurrentTripItem().isGoodRoad
  ///   sets the CurrentTripItem().isGoodRoad
  ///   Adds a Route to CurrentTripItem().goodRoads with waypoints[Waypoint(currentPosition)]
  /// else
  ///   updates the goodRoads.last.route.uuid
  ///   adds a waypoint(Waypoint(currentPosition)) to goodRoads.last.waypoints
  ///   adds a pointOfInterest(uuid, description, sound) to CurrentTripItems().pointsOfInterest
  ///
  updateRouteType({String description = '', String sound = ''}) {
    if (CurrentTripItem().isGoodRoad) {
      CurrentTripItem().goodRoadEnd(description: description, sounds: sound);
    } else {
      CurrentTripItem().requestGreatRoad();
      if (update != null) {
        update!(true);
      }
    }
  }
}
