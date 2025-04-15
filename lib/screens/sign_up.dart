import 'package:flutter/material.dart';
import 'package:drives/models/other_models.dart';
import 'package:drives/services/services.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  //int sound = 0;
  String email = 'james@eggxactly.com';
  String password = 'ohmy10';
  int manufacturer = 0;
  int model = 0;
  bool carData = false;
  bool userExists = false;
  String savedPassword = '';
  bool dataComplete = false;
  List<String> titles = [
    'Register as new user',
    'Update your details',
    'Reset your password'
  ];
  List<String> descriptions = [
    'You will be emailed a six digit validation code.\n Please check your emails (and spam foledr).\n You can then complete your registration.',
    'Please update your details',
    'You will be emailed a six digit validation code.\n Please check your emails (and spam folder).'
  ];
  List<String> captions = ['Register', 'Update', 'Reset'];
  int mode = 0;
  final Key _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();

  final ButtonStyle style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(60),
      backgroundColor: Colors.blue,
      shadowColor: Colors.grey,
      elevation: 10,
      textStyle: const TextStyle(fontSize: 30, color: Colors.white));

  @override
  void initState() {
    super.initState;
    userExists =
        Setup().user.email.isNotEmpty && Setup().user.surname.isNotEmpty;
    savedPassword = Setup().user.password;
    Setup().user.password = '';
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => FocusScope.of(context).requestFocus(_focusNode));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mode = Setup().user.surname.isEmpty
        ? 0
        : Setup().user.password.isEmpty
            ? 2
            : 1;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),

        /// Removes Shadow
        toolbarHeight: 40,
        title: const Text(
          'Drives user details',
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
              titles[mode],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        /// Shrink height a bit
        leading: BackButton(
          onPressed: () {
            try {
              if (Setup().user.password.isEmpty) {
                Setup().user.password = savedPassword;
              }
              if (userExists) {
                saveUser(Setup().user);
              } else {
                insertSetup(Setup());
              }
              Navigator.pop(context);
            } catch (e) {
              debugPrint('Setup error: ${e.toString()}');
            }
          },
        ),
      ),
      body: portraitView(),
      // body: MediaQuery.of(context).orientation == Orientation.portrait ? portraitView() : landscapeView()
    );
  }

  Widget portraitView() {
    // setup =  Settings().setup;
    // if (Setup().user.forename.isEmpty) {
    //   focusNode.requestFocus();
    // }
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUnfocus,
        child: Expanded(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          // autofocus: true,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your forename',
                            labelText: 'Forename',
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          textAlign: TextAlign.left,
                          initialValue: Setup().user.forename.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (text) =>
                              setState(() => Setup().user.forename = text),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your forename';
                            }
                            return null;
                          }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter surname',
                            labelText: 'Surname',
                          ),
                          textAlign: TextAlign.left,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          initialValue: Setup().user.surname.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          onChanged: (text) =>
                              setState(() => Setup().user.surname = text),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter your surname';
                            }
                            return null;
                          }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextFormField(
                    readOnly: false, //Setup().user.email.isNotEmpty,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your email address',
                      labelText: 'Email address',
                    ),
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.left,
                    initialValue: Setup().user.email.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) =>
                        setState(() => Setup().user.email = text),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your email address';
                      }
                      return null;
                    }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your phone number',
                      labelText: 'Phone number',
                    ),
                    textInputAction: TextInputAction.next,
                    textAlign: TextAlign.left,
                    initialValue: Setup().user.phone.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) =>
                        setState(() => Setup().user.phone = text),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    }),
              ),
              if (savedPassword.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your password',
                      labelText: 'Password',
                    ),
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    initialValue: Setup().user.password.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    validator: (val) => Setup().user.password.length < 8
                        ? 'Minimum password length is 8'
                        : null,
                    onChanged: (text) =>
                        setState(() => Setup().user.password = text),
                  ),
                ),
              if (userExists && savedPassword.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Change password',
                      labelText: 'New password',
                    ),
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    initialValue: Setup().user.password.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
                    onChanged: (text) =>
                        setState(() => Setup().user.newPassword = text),
                  ),
                )
              ],
              if (carData) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Car Manufacturer',
                    ),
                    value: manufacturers[0],
                    items: manufacturers
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item,
                                style: Theme.of(context).textTheme.bodyLarge!),
                          ),
                        )
                        .toList(),
                    onChanged: (item) => setState(() =>
                        manufacturer = manufacturers.indexOf(item.toString())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Car Model',
                    ),
                    value: models[0],
                    items: models
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item,
                                  style:
                                      Theme.of(context).textTheme.bodyLarge!),
                            ))
                        .toList(),
                    onChanged: (item) =>
                        setState(() => model = models.indexOf(item.toString())),
                  ),
                )
              ],
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
                  child: Text(descriptions[mode],
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
                  child: ActionChip(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onPressed: () {
                      saveUser(Setup().user);
                      postUser(user: Setup().user, register: true);
                    },
                    backgroundColor: Colors.blue,
                    avatar: const Icon(
                      Icons.how_to_reg,
                      color: Colors.white,
                    ),
                    label: Text(captions[mode],
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
