import 'package:flutter/material.dart';
import 'package:drives/models.dart';

class MyTripTile extends StatefulWidget {
  final MyTripItem myTripItem;

  const MyTripTile({
    super.key,
    required this.myTripItem,
  });

  @override
  State<MyTripTile> createState() => _myTripTileState();
}

class _myTripTileState extends State<MyTripTile> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Material(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                    /*
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
              */
                    child: ExpansionTile(
                        //   collapsedShape: const RoundedRectangleBorder(
                        //       side: BorderSide(style: BorderStyle.solid),
                        //       borderRadius: BorderRadius.all(Radius.circular(10))),
                        title: Column(children: [
                          Row(children: [
                            /* const Expanded(
                            flex: 5,
                            child: SizedBox(
                                width: 200,
                                child: Image(
                                    image:
                                        AssetImage('assets/images/map.png')))),
                                        */
                            Expanded(
                                flex: 8,
                                child: Text(widget.myTripItem.heading,
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                          ]),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
                              child: Row(children: [
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.route),
                                    Text(
                                        '${widget.myTripItem.distance} miles long')
                                  ]),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.landscape),
                                    Text(
                                        '${widget.myTripItem.pointsOfInterest.length} highlights')
                                  ]),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(children: [
                                    const Icon(Icons.social_distance),
                                    Text(
                                        '${widget.myTripItem.closest} miles away')
                                  ]),
                                ),
                              ]))
                        ]),
                        backgroundColor: Colors.white,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            // _scrollReorderListView = expanded;
                          });
                        },
                        children: [
                      SizedBox(
                          // height: 200,
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                              child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      5, 0, 5, 10),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  widget.myTripItem.subHeading,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.left,
                                                ),
                                              )),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        if (widget
                                            .myTripItem.imageUrls.isNotEmpty)
                                          Row(children: <Widget>[
                                            Expanded(
                                                flex: 8,
                                                child: SizedBox(
                                                    height: 200,
                                                    child: ListView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      children: [
                                                        for (int i = 0;
                                                            i <
                                                                widget
                                                                    .myTripItem
                                                                    .imageUrls
                                                                    .length;
                                                            i++)
                                                          SizedBox(
                                                              width: 200,
                                                              child: Image(
                                                                  image: AssetImage(widget
                                                                      .myTripItem
                                                                      .imageUrls[i]))),
                                                        const SizedBox(
                                                          width: 30,
                                                        ),
                                                      ],
                                                    )))
                                          ]),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                            child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 0, 5, 10),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(widget.myTripItem.body,
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20),
                                                textAlign: TextAlign.left),
                                          ),
                                        )),
                                        SizedBox(
                                            child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 0, 5, 10),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: TextButton(
                                              child: const Row(children: [
                                                Icon(Icons.upload),
                                                Text('Load Trip')
                                              ]),

                                              // icon: const Icon(Icons.upload),
                                              onPressed: () => (),
                                            ),
                                          ),
                                        )),
                                      ]))))
                    ])))));
  }

  changeRating(value) {
    //  setState(() {
    //    widget.tripItem.score = value;
    //  });
  }
}
