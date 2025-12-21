import 'package:flutter/material.dart';
import 'dart:convert';
// import 'package:material_symbols_icons/get.dart';
// import 'package:material_symbols_icons/material_symbols_icons.dart';
// import 'package:material_symbols_icons/get.dart';
import '/models/other_models.dart';
import '/services/services.dart';
import '/classes/classes.dart';

// https://pinetools.com/add-text-each-line

List<String> stands = [
  "5-815",
  "5-150",
  "5-830",
  "5-235",
  "5-230",
  "4-455",
  "5-852",
  "4-450",
  "4-160",
  "5-350",
  "4-355",
  "4-350",
  "5-345",
  "5-950",
  "4-755",
  "5-740",
  "5-390",
  "5-510",
  "5-700",
  "5-975",
  "5-070",
  "5-155",
  "5-145",
  "5-828",
  "5-778",
  "5-384",
  "5-258",
  "5-462",
  "5-378",
  "5-775",
  "5-848",
  "5-525",
  "4-340",
  "5-425",
  "5-240",
  "5-260",
  "5-265",
  "5-568",
  "5-360",
  "5-560",
  "5-565",
  "5-460",
  "5-900",
  "5-870",
  "5-760",
  "5-800",
  "5-745",
  "5-250",
  "5-530",
  "5-735",
  "5-420",
  "5-960",
  "5-860",
  "5-245",
  "4-020",
  "5-548",
  "5-850",
  "5-818",
  "5-435",
  "5-780",
  "5-925",
  "5-750",
  "5-855",
  "5-030",
  "5-440",
  "5-910",
  "5-782",
  "5-575",
  "5-330",
  "5-475",
  "5-025",
  "5-720",
  "5-570",
  "4-022",
  "4-750",
  "5-135",
  "5-138",
  "5-388",
  "4-560",
  "5-730",
  "5-515",
  "4-760",
  "4-650",
  "4-550",
  "5-765",
  "5-755",
  "3-460",
  "5-484",
  "5-488",
  "5-130",
  "5-375",
  "5-825",
  "5-742",
  "4-360",
  "5-480",
  "5-520",
  "5-340",
  "5-725",
  "5-380",
  "5-845",
  "5-370",
  "5-140",
  "5-060",
  "5-710",
  "5-715",
  "5-050",
  "4-460",
  "4-765",
  "5-865",
  "5-586",
  "5-588",
  "5-590",
  "5-580",
  "5-470",
  "5-595",
  "5-790",
  "5-365",
  "3-280",
  "3-285",
  "5-255",
  "5-040",
  "5-400",
  "5-472",
  "5-270 & 5-180",
  "5-540",
  "5-770",
  "5-762",
  "4-465",
  "5-920",
  "5-430",
  "4-435",
  "5-718",
  "5-820",
  "5-490",
  "5-784",
  "5-840",
  "5-578",
  "5-584",
  "5-465",
  "5-768",
  "5-772",
  "5-170",
  "5-970",
  "5-788",
  "3-290",
  "5-545",
  "5-832",
  "5-810",
  "3-260",
  "5-835",
  "3-360",
  "3-270",
  "5-410",
  "4-768",
  "5-395",
  "5-838",
  "4-430",
  "4-440",
  "5-142",
  "5-160",
  "5-165",
  "5-415",
];
List<String> standNames = [
  "1381 Motor Club",
  "2CVGB",
  "ado16.info",
  "Alfa Romeo Owners Club",
  "Alfa Romeo Owners Club 916 Register",
  "Allard Owners Club",
  "Allegro Club International",
  "Alvis Owner Club",
  "Armstrong Siddeley Owners Club",
  "AstonOwners.com",
  "Austin A30 A35 Owners Club",
  "Austin Counties Car Club",
  "Austin Healey Club",
  "Austin Maxi Owners Club",
  "Austin Ten Drivers Club",
  "Auto Anonymous",
  "Beach buggy.info",
  "Black Country Classic Car Club",
  "Boston Classic Car Club",
  "British Historic Kart Club",
  "Capri 280 Group",
  "Citroen Car Club",
  "Club Audi",
  "Club Calibra",
  "Club Triumph",
  "Coleshillautobreakfastmeet",
  "Corrado Club of Great Britain",
  "Cortina MK3 Club",
  "Corvette Appreciation & Preservation Society",
  "Crayford Convertible Car Club",
  "CVC Register",
  "Daimler & Lanchester Owners’ Club",
  "Enthusiasts of British Motor Vehicles",
  "Federation of British Historic Vehicle Clubs",
  "Fiat Motor Club (G.B.) & Fiat Panda Club",
  "Ford Consul Classic and Capri Owners Club",
  "Ford Corsair Owners Club",
  "Ford Granada Mk1 & Mk2 Drivers Guild",
  "Ford RS Owners Club",
  "Ford Sidevalve Owners’ Club",
  "Ford-100e.com",
  "Fordsport",
  "Frisky Register",
  "GCCG",
  "GTOUK",
  "Heinkel Trojan Club",
  "Historic Marathon Rally Group",
  "Historic Volkswagen Club",
  "Jaguar Drivers’ Club",
  "Jaguar XJS Club",
  "Jensen Owners Club",
  "Jowett Car Club",
  "Klasyczna Polonia",
  "Lancia Beta Forum / Thema and Dedra Consortium",
  "Landcrab Owners Club",
  "Leicester Classic Car Enthusiasts",
  "Leyland Princess and Ambassador Enthusiasts’ Club",
  "Long Buckby Vintage and Classic Vehicle Meet",
  "Lotus Grand Tourers",
  "Maestro & Montego Owners Club",
  "Maico Owners Club",
  "Marcos Owners Club",
  "Marina & Ital Club",
  "Matra Enthusiasts Club UK",
  "Mercedes-Benz Club",
  "Messerschmitt Owners Club",
  "Metro Owners Club",
  "MG Car Club MGF Register",
  "MG Owners Club",
  "MG SV Club",
  "Midas Owners Club",
  "Midget and Sprite Club",
  "Midland Old School Ford",
  "Midland Vehicle Preservation Society",
  "Midlands Austin Seven Club",
  "Midlands Mini Club",
  "MINI Y / MINI O2 S / Cabri04 Register",
  "Minikits",
  "Minor LCV Register",
  "Modern Classic Executive Cars Group",
  "Morgan Sports Car Club",
  "Morris Minor Community",
  "Morris Minor Owners Club",
  "Morris Register",
  "MR2 Drivers Club",
  "MX-5 Owners Club",
  "Nordik Rides",
  "Norfolk and Norwich Rover Owners Club",
  "Norwich Classic Vehicle Club",
  "NW Minis",
  "Official US Cop Cars UK",
  "Opel Manta Owners Club",
  "Owen Motoring Club",
  "Oxford Universities Motorsport Foundation",
  "P6 Rover Owners Club",
  "Porsche 924 Owners Club",
  "Porsche Club GB",
  "Porsche Enthusiasts Club",
  "Pre29 Members of National Street Rod Assn",
  "Project Jay Preservation Group",
  "Quantum Owners Club",
  "quattro Owners Club",
  "Racing-Puma.co.uk",
  "Reliant Owners Club",
  "Reliant Sabre & Scimitar Owners Club",
  "Renault Owners Club",
  "Riley Motor Club",
  "Riley RM Club",
  "Rolls-Royce Employees Motor Club",
  "Rover & MG Enthusiasts Club",
  "Rover 200 & 400 Owners Club",
  "Rover 600 & 800 Owners Club",
  "Rover Coupe Owners Club",
  "Rover Owners Club",
  "Rover SD1 Club",
  "Rover Sports Register",
  "RS500 Owners",
  "Saab Enthusiasts Club",
  "Saab Owners Club of Great Britain",
  "Scirocco Register",
  "Simca Club UK",
  "Skoda Owners Club GB",
  "Splinter Cell Car Club",
  "Sporting Bears",
  "Staffordshire Moorlands Ind Porsche Owners Club",
  "Standard Motor Club",
  "Stateside COPS and Service Vehicles UK",
  "Stourbridge Pre War Car Club",
  "Sunbeam Alpine Owners Club",
  "Sunbeam Lotus Owners’ Club",
  "Swallow Register",
  "The Bug Club",
  "The Imp Club",
  "The Rover P6 Club",
  "The Triumph Sports Six Club",
  "The Vauxhall FD and FE Owners Club",
  "The ZR / ZS / ZT Register",
  "the BRM.co.uk",
  "Tickford Owners Club",
  "Toyota Enthusiasts Club",
  "TR Drivers Club",
  "Transit Van Club",
  "Triumph Dolomite Club",
  "Triumph Roadster Club",
  "UK Saabs",
  "United Kingdom Probe Owners Club",
  "Vauxhall Astra Mk2 Owners Club",
  "VBOA",
  "VEC2010",
  "Viva Drivers Club",
  "Volvo Enthusiasts Club",
  "Volvo Owners’ Club",
  "Wartburg Trabant IFA Club UK",
  "West Berkshire Classic Vehicle Club",
  "West Coast Classic Car Club",
  "West Midlands Allsorts",
  "Wolseley Hornet Special Club",
  "Wolseley Register",
  "X1/9 Owners Club",
  "XR Owners Club",
  "XR4 Register",
  "Young Retro Motor Club",
];

List<Stand> _stands = [];

List<String> standsSorted = [];

List<String> positions = [
  'Chairman',
  'Secretary',
  'Committee member',
  'Member'
];

List<String> feedbacks = [
  'Concept',
  'Usefulness',
  'Sharing drives',
  'Beta test'
];

List<String> contact = ['Met at event', 'Referred on stand', 'Met before'];

List<String> actions = [
  'Email details',
  'Call soon',
  'Follow up in a month',
  'Not interested',
  'Not appropriate'
];

int standIndex = 0;
int _seen = 0;

class SurveyForm extends StatefulWidget {
  // var setup;
  const SurveyForm({super.key, setup});
  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  //int sound = 0;
  String _title = 'Drives survey';
  late Future<bool> dataLoaded;
  // int _seen = 0;
  @override
  void initState() {
    super.initState();
    _stands.clear();
    standsSorted.clear();
    for (int i = 0; i < stands.length; i++) {
      _stands.add(Stand(index: i, name: standNames[i], stand: stands[i]));
      standsSorted.add(stands[i]);
    }
    standsSorted.sort();
    dataLoaded = getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            try {
              getPrivateRepository().insertSetup(Setup());
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),

        /// Removes Shadow
        title: Text(_title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              'Survey - seen: $_seen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit

        actions: const <Widget>[],
      ),

      body: FutureBuilder<bool>(
        future: dataLoaded,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Snapshot error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            // _building = false;
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
          throw ('Error - FutureBuilder insurvey.dart');
        },
      ),

      //body: portraitView(),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Future<bool> getData() async {
    //await alterSurveyTables();
    List<Map<String, dynamic>> standMaps =
        await getPrivateRepository().getSurveyData(table: 'stands');
    debugPrint('${standMaps.length} stand records found');
    _seen = standMaps.length;
    try {
      for (Map<String, dynamic> map in standMaps) {
        Stand stand = Stand.fromMap(map: map);
        List<Map<String, dynamic>> contactMaps = await getPrivateRepository()
            .getSurveyData(table: 'contacts', standId: stand.id);
        if (contactMaps.isNotEmpty) {
          stand.contacts.clear();
        }
        for (Map<String, dynamic> contactMap in contactMaps) {
          stand.contacts.add(Contact.fromMap(map: contactMap));
        }
        int index = stands.indexOf(stand.stand);
        if (index >= 0) {
          _stands[index] = stand;
          _stands[index].seen = true;
        }
      }
      return true;
    } catch (e) {
      debugPrint('getData error: ${e.toString()}');
      return false;
    }
  }

  Widget portraitView() {
    return SingleChildScrollView(
      child: Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    items: dropdowniItems(items: standsSorted, name: 'stand'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Stand number',
                    ),
                    initialValue: stands[standIndex],
                    //      items: colourChoices(context),
                    onChanged: (chosen) {
                      standIndex = stands.indexOf(chosen!);
                      _title = standNames[standIndex];
                      setState(() {});
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Text('Seen',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Checkbox(
                      //  title: Text('Seen'),
                      value: _stands[standIndex].seen,
                      onChanged: (value) async {
                        _stands[standIndex].seen = value ?? false;
                        _seen = value! ? _seen + 1 : _seen - 1;
                        if (value == true) {
                          Map<String, dynamic> map =
                              _stands[standIndex].toMap();
                          int id = await getPrivateRepository()
                              .saveSurveyData(map: map, table: 'stands');
                          _stands[standIndex].id = id;
                          for (Contact contact
                              in _stands[standIndex].contacts) {
                            contact.standId = id;
                            map = contact.toMap();
                            await getPrivateRepository()
                                .saveSurveyData(map: map, table: 'contacts');
                          }
                        }
                        setState(() => ());
                      },
                    ),
                  ),
                ]),
              ),
            ]),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: DropdownButtonFormField<String>(
                      items: dropdowniItems(items: standNames, name: 'owner'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Stand name',
                      ),
                      initialValue: standNames[standIndex].trim(),
                      onChanged: (chosen) => setState(() {
                        _title = chosen!;
                        standIndex = standNames.indexOf(chosen);
                      }),
                      //  uiColours.keys.toList().toString().indexOf(item.toString())),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: DropdownButtonFormField<String>(
                      items: dropdowniItems(items: actions, name: 'action'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Action',
                      ),
                      initialValue: actions[0].trim(),
                      onChanged: (chosen) => setState(() =>
                          (_stands[standIndex].action = chosen.toString())),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: Row(children: [
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                          color: Colors.blue,
                          iconSize: 30,
                          onPressed: () => setState(() {
                            _stands[standIndex].contacts.add(Contact());
                          }),
                          icon: Icon(
                            Icons.add,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          color: Colors.blue,
                          iconSize: 30,
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                          onPressed: () =>
                              saveAllStands(), //   saveStand(index: standIndex),
                          icon: Icon(Icons.save, color: Colors.blue),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          color: Colors.blue,
                          iconSize: 30,
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                          onPressed: () =>
                              uploadAll(), //   saveStand(index: standIndex),
                          icon: Icon(Icons.upload, color: Colors.blue),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            // ContactTile(contact: _stands[standIndex].contacts[0], index: 0),
            // ...getTiles(),

            ...List.generate(
              _stands[standIndex].contacts.length,
              (index) => ContactTile(
                  index: index, contact: _stands[standIndex].contacts[index]),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> dropdowniItems(
      {required List<String> items, String name = ''}) {
    return List.generate(
      items.length,
      (index) => DropdownMenuItem(
        key: Key('$name$index'),
        value: items[index].trim(),
        child: Row(
          children: [
            if (name == 'stand')
              Checkbox(
                  value: _stands[stands.indexOf(items[index])].seen,
                  onChanged: (_) => ()),
            Text(items[index].trim(),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!),
            //  )
          ],
        ),
      ),
    );
  }
}

uploadAll() async {
  List<Map<String, dynamic>> data = [];
  for (int i = 0; i < _stands.length; i++) {
    if (_stands[i].contacts[0].altered || _stands[i].seen) {
      Map<String, dynamic> standMap = _stands[i].toMap();
      List<Map<String, dynamic>> contacts = [];
      for (int j = 0; j < _stands[i].contacts.length; j++) {
        contacts.add(_stands[i].contacts[j].toMap());
      }
      standMap['contacts'] = contacts;
      data.add(standMap);
    }
  }
  if (data.isNotEmpty) {
    postContacts(data: data);
  }
}

saveAllStands() async {
  for (int i = 0; i < _stands.length; i++) {
    if (_stands[i].contacts[0].altered || _stands[i].seen) {
      await saveStand(index: i);
    }
  }
}

saveStand({int index = -1}) async {
  Map<String, dynamic> map = _stands[index].toMap();
  int id =
      await getPrivateRepository().saveSurveyData(map: map, table: 'stands');

  if (id >= 0) {
    _stands[index].id = id;
    for (Contact contact in _stands[index].contacts) {
      contact.standId = id;
      map = contact.toMap();
      getPrivateRepository().saveSurveyData(map: map, table: 'contacts');
    }
  }
  // _seen = 0;
  for (Stand stand in _stands) {
    if (stand.seen) {
      _seen++;
    }
  }
}

class Stand {
  bool altered = false;
  int id;
  int index;
  String name;
  String stand;
  bool seen;
  List<Contact> contacts = [Contact()];
  String comments = '';
  String action = '';
  String interviewer = '';
  Stand(
      {this.id = -1,
      this.seen = false,
      this.index = 0,
      this.name = '',
      this.stand = '',
      this.comments = '',
      this.action = '',
      this.interviewer = ''});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stand': stand,
      'seen': seen ? 1 : 0,
      'comments': comments,
      'action': action,
      'interviewer': interviewer,
    };
  }

  factory Stand.fromMap({required Map<String, dynamic> map}) {
    return Stand(
        id: map['id'],
        name: map['name'],
        stand: map['stand'],
        seen: map['seen'] == 1,
        comments: map['comments'],
        action: map['action'],
        interviewer: map['interviewer']);
  }
}

class Contact {
  bool altered = false;
  int id;
  int standId;
  String forename;
  String surname;
  String email;
  String phone;
  String position;
  String contact;
  String feedback;
  List<double> ratings = [1, 1, 1, 1];
  Contact({
    this.id = -1,
    this.standId = -1,
    this.forename = '',
    this.surname = '',
    this.phone = '',
    this.email = '',
    this.position = '',
    this.contact = '',
    this.feedback = '',
    ratings,
  });

  factory Contact.fromMap({required Map<String, dynamic> map}) {
    try {
      var mapratings = jsonDecode(map['ratings']) as Map<String, dynamic>;
      List<double> ratings = [
        mapratings['r0'] ?? 1,
        mapratings['r1'] ?? 1,
        mapratings['r2'] ?? 1,
        mapratings['r3'] ?? 1,
      ];
      Contact contact = Contact(
          id: map['id'],
          standId: map['stand_id'],
          forename: map['forename'],
          surname: map['surname'],
          phone: map['phone'],
          email: map['email'],
          position: map['position'],
          contact: map['contact'],
          feedback: map['feedback'],
          ratings: ratings);
      contact.ratings = ratings;
      return contact;
    } catch (e) {
      debugPrint('Contact error: ${e.toString()}');
    }
    return Contact();
  }
  void rate({required int index, required int value}) {
    ratings[index] = value.toDouble();
    return;
  }

  Map<String, dynamic> toMap() {
    var ratings = {
      'r0': this.ratings[0],
      'r1': this.ratings[1],
      'r2': this.ratings[2],
      'r3': this.ratings[3]
    };
    String rating = json.encode(ratings);
    return {
      'id': id,
      'stand_id': standId,
      'forename': forename,
      'surname': surname,
      'email': email,
      'phone': phone,
      'position': position,
      'contact': contact,
      'feedback': feedback,
      'ratings': rating,
    };
  }
}

/*

*/
class ContactTile extends StatefulWidget {
  final int index;
  final Contact contact;

  const ContactTile({
    super.key,
    required this.index,
    required this.contact,
  });
  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  @override
  void initState() {
    super.initState();
  }

  List<DropdownMenuItem<String>> dropdowniItems(
      {required List<String> items, String name = ''}) {
    return List.generate(
      items.length,
      (index) => DropdownMenuItem(
        key: Key('$name$index'),
        value: items[index].trim(),
        child: Row(
          children: [
            Text(items[index].trim(),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge!),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'in ContactTile widget.contact.forename: ${widget.contact.forename}');
    return Card(
      elevation: 5,
      color: const Color.fromARGB(255, 243, 245, 247),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: TextFormField(
                  key: Key('${widget.contact.standId}${widget.index}_1'),
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter forename',
                    labelText: 'Contact forename',
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  textAlign: TextAlign.left,
                  initialValue: widget.contact.forename,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) => setState(() {
                    widget.contact.forename = text;
                    widget.contact.altered = true;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: TextFormField(
                  key: Key('${widget.contact.standId}${widget.index}_2'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter surname',
                    labelText: 'Contact surname',
                  ),
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  initialValue: widget.contact.surname,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: (text) => setState(() {
                    widget.contact.surname = text;
                    widget.contact.altered = true;
                  }),
                ),
              ),
            ),
          ]),
          Row(
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: TextFormField(
                    key: Key('${widget.contact.standId}${widget.index}_3'),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter email address',
                      labelText: 'Email address',
                    ),
                    textAlign: TextAlign.left,
                    initialValue: widget.contact.email,
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) {
                      widget.contact.email = text;
                      widget.contact.altered = true;
                    }),
              )),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: TextFormField(
                      key: Key('${widget.contact.standId}${widget.index}_4'),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter mobile phone number',
                        labelText: 'Mobile phone number',
                      ),
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.phone,
                      initialValue: widget.contact.phone,
                      style: Theme.of(context).textTheme.bodyLarge,
                      onChanged: (text) {
                        widget.contact.phone = text;
                        widget.contact.altered = true;
                      }),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    key: Key('${widget.contact.standId}${widget.index}_5'),
                    items: dropdowniItems(items: positions, name: 'position'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Contacts position',
                    ),
                    initialValue: positions[0].trim(),
                    onChanged: (chosen) => setState(
                        () => (widget.contact.position = chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                  child: DropdownButtonFormField<String>(
                    key: Key('${widget.contact.standId}${widget.index}_6'),
                    items: dropdowniItems(items: contact, name: 'contact'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Contact type',
                    ),
                    initialValue: contact[0].trim(),
                    onChanged: (chosen) => setState(
                        () => (widget.contact.contact = chosen.toString())),
                    //  uiColours.keys.toList().toString().indexOf(item.toString())),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
                  child: TextFormField(
                    key: Key('${widget.contact.standId}${widget.index}_7'),
                    readOnly: false,
                    autofocus: false,
                    maxLines: null, // these 2 lines allow multiline wrapping
                    keyboardType: TextInputType.multiline,
                    textAlign: TextAlign.start,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding:
                          const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                      focusColor: Colors.blueGrey,
                      hintText: 'Enter feedback',
                      labelText: 'Feedback',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    initialValue: widget.contact.feedback,
                    onChanged: (text) => setState(
                      () {
                        widget.contact.feedback = text;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          feedbacks[0],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: StarRating(
                            onRatingChanged: (value) => setState(() =>
                                widget.contact.rate(index: 0, value: value)),
                            rating: widget.contact.ratings[0]),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          feedbacks[1],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: StarRating(
                            onRatingChanged: (value) => setState(() =>
                                widget.contact.rate(index: 1, value: value)),
                            rating: widget.contact.ratings[1]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          feedbacks[2],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: StarRating(
                            onRatingChanged: (value) => setState(() =>
                                widget.contact.rate(index: 2, value: value)),
                            rating: widget.contact.ratings[2]),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 10, 0, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          feedbacks[3],
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: StarRating(
                            onRatingChanged: (value) => setState(() =>
                                widget.contact.rate(index: 3, value: value)),
                            rating: widget.contact.ratings[3]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
