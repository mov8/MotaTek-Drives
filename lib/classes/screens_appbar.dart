import 'package:flutter/material.dart';

/// Use VoidCallback rather than Function to get a stateless Widget
/// to execute a parent method. To exucute the method in the stateless
/// widget don't use () => callback, but just callback

class ScreensAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String heading;
  final String prompt;
  final bool update;
  String? updateHeading;
  String? updateSubHeading;
  final VoidCallback? updateMethod;
  final bool showOverflow;
  final bool showAction;
  final VoidCallback? leadingMethod;
  List<String>? overflowPrompts;
  List<Icon>? overflowIcons;
  List<VoidCallback>? overflowMethods;
  // List<Function(int)>? overflowMethods;

  ScreensAppBar({
    super.key,
    required this.heading,
    required this.prompt,
    this.updateHeading,
    this.updateSubHeading,
    this.updateMethod,
    this.update = false,
    this.showOverflow = false,
    this.showAction = false,
    this.leadingMethod,
    this.overflowPrompts,
    this.overflowIcons,
    this.overflowMethods,
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),

      /// Removes Shadow
      toolbarHeight: 40,
      title: Text(
        heading,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Padding(
          padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: Text(
                  prompt,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (showOverflow) ...[
                Expanded(
                  flex: 1,
/*
 List<String> invState = ['undecided', 'declined', 'accepted'];
 States 0 = Future undecided || accepted
        1 = All undecided || accepted
        2 = All undecided || accepted || declined
*/

                  child: PopupMenuButton(
                    iconColor: Colors.white,
                    itemBuilder: (context) => overflowPrompts!
                        .map<PopupMenuEntry<String>>(
                          (entry) => PopupMenuItem(
                            value: entry,
                            onTap: overflowMethods![
                                overflowPrompts!.indexOf(entry)],
                            child: Row(children: [
                              overflowIcons![overflowPrompts!.indexOf(entry)],
                              SizedBox(width: 5),
                              Text(
                                overflowPrompts![
                                    overflowPrompts!.indexOf(entry)],
                                style: TextStyle(fontSize: 18),
                              )
                            ]),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      /// Shrink height a bit
      leading: IconButton(
        onPressed: () async {
          if (update) {
            await updateDialog(
                context: context,
                heading: updateHeading!,
                subHeading: updateSubHeading!,
                updateMethod: updateMethod);
          }
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        icon: Icon(
          Icons.arrow_back,
          size: 30,
        ),
      ),

      /* BackButton(
        style: ButtonStyle(minimumSize: WidgetStateProperty.),
        onPressed: () async {
          if (update) {
            await updateDialog(
                context: context,
                heading: updateHeading!,
                subHeading: updateSubHeading!,
                updateMethod: updateMethod);
          }

          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ), */
      // if (showOveflow) []
      actions: showAction
          ? [
              IconButton(
                  onPressed: updateMethod, icon: Icon(Icons.check, size: 30))
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 45);
}

Future updateDialog(
        {required BuildContext context,
        String heading = '',
        String subHeading = '',
        Function? updateMethod}) =>
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Upload changes?',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading.isNotEmpty)
                  Text(
                    heading,
                    //   "You have declined ${_refused.length} invitation${_refused.length > 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                if (subHeading.isNotEmpty)
                  Text(
                    subHeading,
                    //    "You have accepted ${_accepted.length} invitation${_accepted.length > 1 ? 's' : ''}",
                    style: TextStyle(fontSize: 20),
                  ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Save your changes now ?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                updateMethod;
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Upload',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Ignore',
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            )
          ],
        ),
      ),
    );
