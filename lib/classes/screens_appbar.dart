import 'package:flutter/material.dart';
import '/helpers/edit_helpers.dart';
import '../services/services.dart';
import 'package:flutter/foundation.dart';
import '../classes/web_appbar.dart';

/// Use VoidCallback rather than Function to get a stateless Widget
/// to execute a parent method. To exucute the method in the stateless
/// widget don't use () => callback, but just callback
///

class ScreensAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String heading;
  final String prompt;
  final bool update;
  String updateHeading;
  String updateSubHeading;
  // final VoidCallback? updateMethod;
  final Function? updateMethod;
  final bool showDrawer;
  final bool showOverflow;
  final bool showAction;
  final VoidCallback? leadingMethod;
  final Icon leadingIcon;
  List<String>? overflowPrompts;
  List<Icon>? overflowIcons;
  List<VoidCallback>? overflowMethods;
  // List<Function(int)>? overflowMethods;

  /// ScreenAppBar is a generalised AppBar for all the setup screens. It handles all
  /// the CRUD methods for use with a device based app.

  ScreensAppBar({
    super.key,
    required this.heading,
    required this.prompt,
    this.updateHeading = '',
    this.updateSubHeading = '',
    this.updateMethod,
    this.update = false,
    this.showDrawer = false,
    this.showOverflow = false,
    this.showAction = false,
    this.leadingMethod,
    this.leadingIcon = const Icon(Icons.arrow_back, size: 30),
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
      leading: IconButton(
        onPressed: () async {
          if (showDrawer) {
            leadingMethod!();
          } else {
            if (update) {
              if (updateHeading == '' && updateMethod != null) {
                await updateMethod!();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                bool upload = await updateDialog(
                    context: context,
                    heading: updateHeading,
                    //    onUpdate: (update) => updateMethod!(update),
                    subHeading: updateSubHeading);
                try {
                  if (upload) {
                    updateMethod!(upload);
                  } else if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('Error: ${e.toString}');
                }
              }
            }
            if (!update && context.mounted) {
              Navigator.pop(context);
            }
          }
        },
        icon: leadingIcon,
      ),
      bottom: ScreensAppBarBottom(
        heading: heading,
        prompt: prompt,
        updateHeading: updateHeading,
        updateSubHeading: updateSubHeading,
        updateMethod: updateMethod,
        update: update,
        //  showDrawer: showDrawer,
        showOverflow: showOverflow,
        showAction: false,
        leadingMethod: leadingMethod,
        //  leadingIcon: leadingIcon,
        overflowPrompts: overflowPrompts,
        overflowIcons: overflowIcons,
        overflowMethods: overflowMethods,
      ),
      actions: showAction
          ? [
              IconButton(
                  onPressed: () => updateMethod!(true),
                  icon: Icon(
                    Icons.check,
                    size: 30,
                    color: Colors.white,
                  ))
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 45);
}

/// ScreenAppBarBottom is a separate widget, because in the Web version the content is shown in
/// the Side Drawer, and not a complete screen. This means the whole AppBar its self isn't shown,
/// only the bottom which adds all the validation and overflow methods. The AppBar bit is taken
/// care of by the WebAppBar that hosts the SideDrawer.

class ScreensAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  Function(int)? onItemClick;
  IconButton? leadingButton;
  List<IconButton>? actionButtons;
  final String heading;
  final String prompt;
  final bool update;
  Color textColor;
  String updateHeading;
  String updateSubHeading;
  // final VoidCallback? updateMethod;
  final Function? updateMethod;
  // final bool showDrawer;
  final bool showOverflow;
  final bool showAction;
  final VoidCallback? leadingMethod;
  Widget? content;
  // final Icon leadingIcon;
  List<String>? overflowPrompts;
  List<Icon>? overflowIcons;
  List<VoidCallback>? overflowMethods;
  // List<Function(int)>? overflowMethods;

  ScreensAppBarBottom({
    super.key,
    this.leadingButton,
    this.onItemClick,
    this.heading = '',
    this.prompt = '',
    this.updateHeading = '',
    this.updateSubHeading = '',
    this.updateMethod,
    this.update = false,
    this.showOverflow = false,
    this.showAction = false,
    this.leadingMethod,
    this.overflowPrompts,
    this.overflowIcons,
    this.overflowMethods,
    this.textColor = Colors.white,
    this.content,
    this.actionButtons,
  });

  final GlobalKey _menuButtonKey = GlobalKey();
  bool _menuExists = false;

  @override
  Widget build(BuildContext context) {
    BuildContext appContext = NavigationService().key.currentContext!;
    _menuExists = false;
    return PreferredSize(
      preferredSize: Size.fromHeight(80),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Row(
              children: [
                if (leadingButton != null) leadingButton!,
                Expanded(
                  flex: 10,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      child: Text(
                        prompt,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                if (actionButtons != null) ...[
                  for (int i = 0; i < actionButtons!.length; i++)
                    actionButtons![i],
                ],
                if (showOverflow) ...[
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      key: _menuButtonKey,
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showCustomMenu(context),
                    ),
                  ),
                  /*
                  Expanded(
                    flex: 1,
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (context) {
                            return PopupMenuButton(
                              useRootNavigator: true,
                              iconColor: textColor,
                              itemBuilder: (appContext) => overflowPrompts!
                                  .map<PopupMenuEntry<String>>(
                                    (entry) => PopupMenuItem(
                                      value: entry,
                                      onTap: overflowMethods![
                                          overflowPrompts!.indexOf(entry)],
                                      child: Row(children: [
                                        overflowIcons![
                                            overflowPrompts!.indexOf(entry)],
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
                            );
                          },
                        ),
                      ], //                   })
                    ),
                  ),
                  */
                  if (showAction) ...[
                    IconButton(
                      onPressed: () => updateMethod!(true),
                      icon: Icon(
                        Icons.check,
                        size: 30,
                        color: textColor,
                      ),
                    )
                  ],
                ],
              ],
            ),
          ),
          if (content != null) content!,
        ],
      ),
    );
  }

  List<Widget>? actions({bool show = false}) {
    return showAction
        ? [
            IconButton(
              onPressed: () => updateMethod!(true),
              icon: Icon(
                Icons.check,
                size: 30,
                color: textColor,
              ),
            ),
          ]
        : null;
  }

  void _showCustomMenu(BuildContext context) async {
    if (!_menuExists) {
      _menuExists = true;
      // 1. Find the position of the button on the screen
      final RenderBox button =
          _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
      final RenderBox overlay = NavigationService()
          .key
          .currentContext!
          .findRenderObject() as RenderBox;
      // Calculate the position for the menu to appear
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          //  button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(Offset(100, 0), ancestor: overlay),
          button.localToGlobal(
              button.size.bottomRight(Offset(100, 0)), // .zero),
              ancestor: overlay),
        ),
        Offset(0, 0) /*.zero */ & overlay.size,
      );
      // 2. Use showMenu with the ROOT navigator's context
      final String? selected = await showMenu<String>(
        constraints: BoxConstraints(minWidth: 250),
        context: NavigationService()
            .key
            .currentContext!, // BREAK OUT: Use the main navigator!
        position: position,
        items: overflowPrompts!
            .map<PopupMenuEntry<String>>(
              (entry) => PopupMenuItem(
                value: entry,
                onTap: overflowMethods![overflowPrompts!.indexOf(entry)],
                child: Row(children: [
                  overflowIcons![overflowPrompts!.indexOf(entry)],
                  SizedBox(width: 5),
                  Text(
                    overflowPrompts![overflowPrompts!.indexOf(entry)],
                    style: TextStyle(fontSize: 18),
                  )
                ]),
              ),
            )
            .toList(),
      );
    }
    _menuExists = false;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 45);
}

Future<bool> updateDialog(
    {required BuildContext context,
    // required Function(bool) onUpdate,
    String heading = '',
    String subHeading = ''}) async {
  // void Function()? updateMethod}) =>
  bool? update = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              'Save changes?',
              style: headlineStyle(
                  context: context, color: Colors.deepOrange, size: 1),
            ),
            content: SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (heading.isNotEmpty)
                    Text(heading,
                        //   "You have declined ${_refused.length} invitation${_refused.length > 1 ? 's' : ''}",
                        style: textStyle(
                            context: context, size: 2, color: Colors.black)),
                  if (subHeading.isNotEmpty)
                    Text(
                      subHeading,
                      //    "You have accepted ${_accepted.length} invitation${_accepted.length > 1 ? 's' : ''}",
                      style: textStyle(
                          context: context, size: 2, color: Colors.black),
                    ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Tap button below.",
                    style: textStyle(
                        context: context, size: 2, color: Colors.black),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Save',
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
      ) ??
      false;

  return update;
}
