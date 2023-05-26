import 'package:flutter/material.dart';
import 'package:code/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

final FirebaseAuth auth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Denter',
      theme: ThemeData(
          primaryColor: Color(0xFF145248),
          primaryColorDark: Color(0xFF145248), //
          primaryColorLight: Color(0xFF145248),
      ),
      home: const AddItem(),
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

  final _reference = FirebaseFirestore.instance.collection('FAZ O L');

  String imageUrl = '';
  String imageName = '';
  File? selectedImage;

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
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Insira o nome'
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
                    await referenceImagetoUpload.putFile(File(file.path));

                    imageUrl = await referenceImagetoUpload.getDownloadURL();
                    imageName = uniqueFileName;
                    setState(() {
                      selectedImage = File(file.path);
                    });
                  } catch (error) {}
                },
                icon: const Icon(Icons.camera_alt)),
            if (selectedImage != null)
              ElevatedButton(
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

                    Map<String, String> dataToSend = {
                      'uid': uid,
                      'nome': nameClient,
                      'telefone': celClient,
                      'foto': imageName,
                    };
                    _reference.add(dataToSend);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('pedido enviado com sucesso')));
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
