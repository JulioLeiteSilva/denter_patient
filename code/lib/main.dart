import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:code/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


final FirebaseAuth auth = FirebaseAuth.instance;






void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  configLoading();
  runApp(const MyApp());
}
void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denter',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const AddItem(),
      builder: EasyLoading.init(),
    );
  }


  const MyApp({super.key});
}


class AddItem extends StatefulWidget {
  const AddItem({Key? key}) : super(key: key);

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {

  final _controllerName = TextEditingController();
  final _controllerTelefone = TextEditingController();

  GlobalKey<FormState> key = GlobalKey();


  final _reference = FirebaseFirestore.instance.collection('emergency');


  String imageUrl = '';
  String imageName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DENTER'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: key,
          child: Column(children: [
            TextFormField(
              controller: _controllerName,
            ),
            TextFormField(
              controller: _controllerTelefone,
            ),
            IconButton(
                onPressed: () async {
                  signInAnon();
                  ImagePicker imagePicker = ImagePicker();
                  XFile? file =
                      await imagePicker.pickImage(source: ImageSource.camera);

                  if (file == null) return;
                  String uniqueFileName =
                      DateTime.now().millisecondsSinceEpoch.toString();

                  Reference referenceRoot = FirebaseStorage.instance.ref();
                  Reference referenceDirImages =
                      referenceRoot.child('emergencies');
                  Reference referenceImagetoUpload =
                      referenceDirImages.child(uniqueFileName);
                  try {
                    await referenceImagetoUpload.putFile(File(file.path));

                    imageUrl = await referenceImagetoUpload.getDownloadURL();
                    imageName = uniqueFileName;
                  } catch (error) {}
                },
                icon: const Icon(Icons.camera_alt)),
            ElevatedButton(
                onPressed: () async {
                  if (imageUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('POR FAVOR INSIRA UMA IMAGEM'),
                    ));

                    return;
                  }
                  final User? user = auth.currentUser;
                  final uid = user!.uid;
                  if (key.currentState!.validate()) {
                    String nameClient = _controllerName.text;
                    String celClient = _controllerTelefone.text;
                    final fcmToken =  await FirebaseMessaging.instance.getToken();
                    Map<String, String?> dataToSend = {
                      'uid': uid,
                      'nome': nameClient,
                      'telefone': celClient,
                      'foto': imageName,
                      'fcm': fcmToken,
                      'status': 'new'
                    };
                    _reference.add(dataToSend);

                    EasyLoading.show(status: 'loading...');



                  }
                },
                child: const Text('ABRIR CHAMADO'))
          ]),
        ),
      ),
    );
  }
}

void signInAnon() async {
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        break;
      default:
    }
  }
  FirebaseAuth.instance.idTokenChanges().listen((User? user) {});


}
