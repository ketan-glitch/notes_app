import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:notes_app/services/date_formatters_and_converters.dart';
import 'package:notes_app/services/extensions.dart';
import 'package:notes_app/services/input_decoration.dart';
import 'package:notes_app/services/route_helper.dart';
import 'package:notes_app/views/base/common_button.dart';
import 'package:notes_app/views/base/custom_appbar.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/firebase_controller.dart';
import '../../../data/models/response/notes.dart';
import '../splash_screen/splash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _gridView = true; // `true` to show a Grid, otherwise a List.

  Stream<List<Note>> readNotes() => FirebaseFirestore.instance
          .collection('users')
          .doc(Get.find<FirebaseController>().firebaseAuth.currentUser!.uid)
          .collection('notes')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          // log("${Get.find<FirebaseController>().firebaseAuth.currentUser?.uid}");
          // log("${doc.data()}", name: "snapshot");
          return Note.fromJson(doc.data());
        }).toList();
      });
  @override
  Widget build(BuildContext context) {
    // log("${Get.find<FirebaseController>().firebaseAuth.currentUser?.email}");
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Notes",
        actions: [
          IconButton(
            onPressed: () async {
              var van = Navigator.of(context);
              await Get.find<FirebaseController>().googleSignIn.signOut();
              van.push(getCustomRoute(child: const SplashScreen()));
            },
            icon: const Icon(Icons.logout),
            color: Colors.black,
          ),
        ],
      ),
      // drawer: AppDrawer(),
      floatingActionButton: _fab(context),
      extendBody: true,
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: SizedBox(height: 24), // top spacing
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: size.height,
              width: size.width,
              child: StreamBuilder<List<Note>>(
                stream: readNotes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final notes = snapshot.data!;
                    // log("${notes.length}", name: "HAS DATA");
                    return GridView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, int index) {
                        return Card(
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notes[index].title.getIfValid.capitalizeFirstOfEach,
                                      style: Theme.of(context).textTheme.headline6,
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: Text(
                                        notes[index].content.getIfValid,
                                        maxLines: 8,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14.0,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      DateFormatters().dateTime.format(notes[index].createdAt!),
                                      style: Theme.of(context).textTheme.headline6!.copyWith(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.0,
                                          ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: PopupMenuButton(
                                    // key: _menuKey,
                                    elevation: 20,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    itemBuilder: (_) => const <PopupMenuItem<String>>[
                                      PopupMenuItem<String>(value: 'Edit', child: Text('Edit')),
                                      PopupMenuItem<String>(value: 'Delete', child: Text('Delete')),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'Edit') {
                                        //EDIT
                                        Navigator.push(
                                          context,
                                          getCustomRoute(
                                            child: AddNote(
                                              title: notes[index].title,
                                              body: notes[index].content,
                                              id: notes[index].id,
                                              createdAt: notes[index].createdAt,
                                            ),
                                          ),
                                        );
                                      }
                                      if (value == 'Delete') {
                                        //Delete
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                    );
                  } else if (snapshot.hasError) {
                    log("${snapshot.error}", name: "ERROR");
                    return const Text("ERROR");
                  } else {
                    log("${snapshot.data}", name: "NO DATA");
                    return _buildBlankView();
                  }
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80.0), // bottom spacing make sure the content can scroll above the bottom bar
          ),
        ],
      ),
    );
  }

  Widget _fab(BuildContext context) => FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, getCustomRoute(child: const AddNote()));
        },
      );

  Widget _buildBlankView() => const Text(
        'Notes you add appear here',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
        ),
      );
}

class AddNote extends StatefulWidget {
  const AddNote({Key? key, this.title, this.body, this.id, this.createdAt}) : super(key: key);
  final String? title;
  final String? body;
  final String? id;
  final DateTime? createdAt;

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  TextEditingController _title = TextEditingController();
  TextEditingController _note = TextEditingController();
  String? id;
  DateTime createdAt = DateTime.now();
  // DateTime updatedAt = DateTime.now();
  Future<void> addNote() async {
    try {
      Map<String, dynamic> data = {
        "title": _title.text,
        "note": _note.text,
        "id": widget.id ?? id,
        "created_at": createdAt,
        "updated_at": DateTime.now(),
      };
      var fireStore = FirebaseFirestore.instance;

      log("${Get.find<FirebaseController>().firebaseAuth.currentUser}");
      await fireStore.collection("users").doc(Get.find<FirebaseController>().firebaseAuth.currentUser?.uid).collection("notes").doc(id).set(data);
      // Navigator.pop(context);
    } catch (error) {
      log("$error");
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      Timer.run(() {
        id = widget.id ?? const Uuid().v1();
        log("${widget.title}");
        log("${widget.body}");
        log("${widget.id}");
        log("${widget.createdAt}");
        if (widget.id.isValid) {
          _title.text = widget.title!;
          _note.text = widget.body!;
          createdAt = widget.createdAt ?? DateTime.now();
          setState(() {});
        }
      });
    } catch (e) {
      log("$e");
    }
  }

  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: "New Note",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
        child: Column(
          children: [
            TextField(
              controller: _title,
              style: Theme.of(context).textTheme.headline4,
              onChanged: (value) {
                if (timer != null) {
                  timer!.cancel();
                }
                timer = Timer(const Duration(seconds: 2), () {
                  addNote();
                });
              },
              decoration: CustomDecoration.inputDecoration(
                label: "Title",
                hint: "Title",
                labelStyle: Theme.of(context).textTheme.headline4!.copyWith(),
                hintStyle: Theme.of(context).textTheme.headline4!.copyWith(),
                // floating: true,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _note,
                minLines: 20,
                maxLines: 40,
                scrollPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                autofocus: true,
                keyboardType: TextInputType.multiline,
                style: Theme.of(context).textTheme.headline6!.copyWith(
                      fontSize: 14.0,
                    ),
                onChanged: (value) {
                  if (timer != null) {
                    timer!.cancel();
                  }
                  timer = Timer(const Duration(seconds: 2), () {
                    addNote();
                  });
                },
                decoration: CustomDecoration.inputDecoration(
                  fillColor: Colors.white,
                  label: "Start writing",
                  hint: "Start writing",
                  labelStyle: Theme.of(context).textTheme.headline6!.copyWith(
                        fontSize: 14.0,
                      ),
                  hintStyle: Theme.of(context).textTheme.headline6!.copyWith(
                        fontSize: 14.0,
                      ),
                  // floating: true,
                ),
              ),
            ),
            CustomButton(
              type: ButtonType.primary,
              onTap: () {
                addNote().then((value) => Navigator.pop(context));
              },
              title: "Save",
            ),
          ],
        ),
      ),
    );
  }
}
