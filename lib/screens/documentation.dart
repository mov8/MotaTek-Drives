import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:html/parser.dart' show parse;
// import 'package:html/dom.dart';
import '/services/services.dart';

class DocumentationForm extends StatefulWidget {
  const DocumentationForm({super.key, setup});
  @override
  State<DocumentationForm> createState() => _DocumentationFormState();
}

class _DocumentationFormState extends State<DocumentationForm> {
  late Future<bool> _dataloaded;

  String _htmlData = '';

  @override
  void initState() {
    super.initState();
    _dataloaded = dataFromWeb();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    super.dispose();
  }

  Future<bool> dataFromDatabase() async {
    return true;
  }

  Future<bool> dataFromWeb() async {
    // _htmlData = await getDocs();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives Documentation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Text(
              "Version v1.0 beta",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<bool>(
        future: _dataloaded,
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
                child: CircularProgressIndicator(),
              ),
            );
          }
          throw ('Error - FutureBuilder group.dart');
        },
      ),
    );
  }

  Widget portraitView() {
    /*
    return SingleChildScrollView(
      child: Html(data: _htmlData),
            Icons.home,
      Icons.route,
      Icons.map,
      Icons.person,
      Icons.shopping_bag,
      Icons.chat_bubble
    );
    */
    return Padding(
      padding: EdgeInsets.fromLTRB(50, 0, 5, 40),
      child: Column(
        children: [
          Expanded(child: Icon(Icons.menu, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.arrow_back, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.auto_stories_outlined,
                  size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.summarize_outlined,
                  size: 50, color: Colors.white)),
          Expanded(
              child:
                  Icon(Icons.mobile_friendly, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.home_outlined, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.route_outlined, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.map_outlined, size: 50, color: Colors.white)),
          Expanded(
              child:
                  Icon(Icons.person_outlined, size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.shopping_bag_outlined,
                  size: 50, color: Colors.white)),
          Expanded(
              child: Icon(Icons.chat_bubble_outline,
                  size: 40, color: Colors.white)),
        ],
      ),
    );
  }

  /* 
  Future<String> fetchHelpSection(String pageUrl, String sectionId) async {
  final response = await http.get(Uri.parse(pageUrl));

  if (response.statusCode == 200) {
    var document = parse(response.body);
    // Find the element by its ID
    Element? sectionElement = document.getElementById(sectionId);

    if (sectionElement != null) {
      // You might want to return innerHtml or outerHtml depending on your needs
      return sectionElement.innerHtml ?? 'Section content not found.';
    } else {
      return 'Section with ID "$sectionId" not found on page.';
    }
  } else {
    throw Exception('Failed to load help page: ${response.statusCode}');
  }
}
  */
}
