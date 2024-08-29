import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';

class HomeTile extends StatefulWidget {
  final HomeItem homeItem;

  const HomeTile({
    super.key,
    required this.homeItem,
  });

  @override
  State<HomeTile> createState() => _homeTileState();
}

class _homeTileState extends State<HomeTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Card(
            child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 400,
                            child: FittedBox(
                                child: Image.asset(
                              widget.homeItem.imageUrl,
                            )),

                            // height: 300, //MediaQuery.of(context).size.height, //400,
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(widget.homeItem.heading,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left),
                              ))),
                      SizedBox(
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                widget.homeItem.subHeading,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                              ),
                            )),
                      ),
                      SizedBox(
                          child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(widget.homeItem.body,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 20),
                              textAlign: TextAlign.left),
                        ),
                      )),
                      SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () => (setState(() {}))),
                          ),
                        ),
                      ),
                    ]))));
  }
}


/*

main.dart
import 'package:flutter/material.dart';

final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _controller = TextEditingController();
  String inputString = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(inputString),
            RaisedButton(
              child: Text("Show Dialog"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Setting String"),
                      content: TextFormField(
                        controller: _controller,
                      ),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.pop(context, _controller.text);
                          },
                        )
                      ],
                    );
                  },
                ).then((val) {
                  setState(() {
                    inputString = val;
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
*/