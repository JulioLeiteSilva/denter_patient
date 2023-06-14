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

import 'maps.dart'; // Importe o arquivo maps.dart aqui

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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denter',
      theme: ThemeData(
        primaryColor: Color(0xFFF30000),
        primaryColorDark: Color(0xFF145248), //
        primaryColorLight: Color(0xFF145248),
      ),
      home: const AddItem(),
      builder: EasyLoading.init(),
    );
  }
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
  File? selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DENTER'),
        backgroundColor: Color(0xFF145248),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: key,
          child: Column(
            children: [
              TextFormField(
                controller: _controllerName,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Insira o nome',
                ),
              ),
              TextFormField(
                controller: _controllerTelefone,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Insira o telefone',
                ),
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
                    EasyLoading.show(status: 'loading...');
                    await referenceImagetoUpload.putFile(File(file.path));

                    imageUrl =
                    await referenceImagetoUpload.getDownloadURL();
                    imageName = uniqueFileName;
                    setState(() {
                      selectedImage = File(file.path);
                    });
                  } catch (error) {} finally {
                    EasyLoading.dismiss();
                  }
                },
                icon: const Icon(Icons.camera_alt),
              ),
              if (selectedImage != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF145248),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Image.file(selectedImage!),
                        );
                      },
                    );
                  },
                  child: const Text('Ver Imagem'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF145248),
                ),
                onPressed: () async {
                  if (imageUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('POR FAVOR INSIRA UMA IMAGEM'),
                      ),
                    );
                    EasyLoading.dismiss();
                    return;
                  }
                  final User? user = auth.currentUser;
                  final uid = user!.uid;
                  if (key.currentState!.validate()) {
                    String nameClient = _controllerName.text;
                    String celClient = _controllerTelefone.text;
                    EasyLoading.show(status: 'loading...');
                    final fcmToken =
                    await FirebaseMessaging.instance.getToken();
                    Map<String, String?> dataToSend = {
                      'uid': uid,
                      'nome': nameClient,
                      'telefone': celClient,
                      'foto': imageName,
                      'fcm': fcmToken,
                      'status': 'new'
                    };
                    _reference.add(dataToSend);

                    EasyLoading.dismiss();
                    EasyLoading.showSuccess("complete");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SecondScreen(), // Substitua MapsScreen pela nova tela que você deseja exibir
                      ),
                    );
                  }
                },
                child: const Text('ABRIR CHAMADO'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF145248),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecondScreen(), // Substitua MapsScreen pela nova tela que você deseja exibir
                    ),
                  );
                },
                child: const Text('Navegar para Maps'),
              ),
            ],
          ),
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

class EmergencyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Aceites'),
        backgroundColor: Color(0xFF145248),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('accept').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhum item de emergência encontrado.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var emergencyData =
              snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(emergencyData['dentist']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Lógica para aceitar o item de emergência
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.green),
                      child: Text('Aceitar'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Lógica para rejeitar o item de emergência
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.red),
                      child: Text('Rejeitar'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
