import '/classes/classes.dart';
import 'package:flutter/material.dart';
import '/helpers/edit_helpers.dart';
// import 'package:flutter/services.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/services/web_helper.dart';
import '/constants.dart';

class DeleteTripsForm extends StatefulWidget {
  const DeleteTripsForm({super.key});

  @override
  State<DeleteTripsForm> createState() => _DeleteTripsFormState();
}

class _DeleteTripsFormState extends State<DeleteTripsForm> {
  final List<TripSummary> _drives = [];
  bool editing = false;
  TextInputAction action = TextInputAction.done;
  int selected = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<List<TripSummary>> _loadTrips(
      {required List<TripSummary> tripSummaries}) async {
    if (tripSummaries.isEmpty) {
      try {
        //     debugPrint('_loadTrips called');
        tripSummaries.addAll(await getTripSummaries(
            northEast: ukNorthEast, southWest: ukSouthWest));
      } catch (e) {
        debugPrint('Error downloading trip summaries = ${e.toString()}');
      }
    }
    return tripSummaries;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: ScreensAppBar(
        heading: 'Drives Admin',
        prompt: 'Remove trips permanently from server', //_prompt,
        updateHeading: 'You have marked trips for deletion.',
        updateSubHeading: 'Delete trips or Ignore changes',
        update: selected > 0,
        showAction: selected > 0,
        updateMethod: (_) => deleteTrips(trips: _drives),
      ),

      body: FutureBuilder<List<TripSummary>>(
        future: _loadTrips(tripSummaries: _drives),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot has error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            //  _drives.addAll(snapshot.data ?? []);
            return portraitView();
          } else {
            return const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            );
          }
          throw ('Error - FutureBuilder group.dart');
        },
      ), //portraitView(),
    );
  }

  Column portraitView() {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: (MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              kBottomNavigationBarHeight -
              20 * 0.93), // 200,
          child: ListView.builder(
            itemCount: _drives.length,
            itemBuilder: (context, index) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Card(
                child: CheckboxListTile(
                  title: Column(children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _drives[index].title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(_drives[index].subTitle),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        StarRating(
                            onRatingChanged: (val) =>
                                {debugPrint('Rating $val')},
                            rating: _drives[index].score)
                      ],
                    ),
                  ]),
                  value: _drives[index].id == 1,
                  onChanged: (value) {
                    setState(
                      () {
                        _drives[index].id = value! ? 1 : -1;
                        selected += value ? 1 : -1;
                      },
                    );
                  },
                ),
                // ToDo: calculate how far away
              ),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ActionChip(
            onPressed: () => deleteTrips(
                trips: _drives), // deleteMember(widget.groupMember!.id),
            backgroundColor: Colors.blue,
            avatar: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
            label: Text('Delete $selected Trips',
                style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  deleteTrips({required List<TripSummary> trips}) async {
    List<Map<String, String>> items = [];
    String uris = '';
    for (TripSummary trip in trips) {
      if (trip.id == 1) {
        uris = "$uris, '${trip.uri}'";
        if (uris.length > 30) {
          items.add({'delete': uris.substring(2)});
          uris = '';
        }
      }
    }
    if (uris.isNotEmpty) {
      items.add({'delete': uris.substring(2)});
    }
    if (items.isNotEmpty) {
      await deleteWebTrip(uriMap: items);
    }
    setState(() {
      selected = 0;
      trips.removeWhere((trip) => trip.id == 1);
    });
  }

  void onConfirmDeleteMember(int value) {
    // debugPrint('Returned value: ${value.toString()}');
    if (value > -1) {
      //   deleteGroupMemberById(value);
      //  widget.groupMember?.index = -1;
      Navigator.pop(context);
    }
  }
}
