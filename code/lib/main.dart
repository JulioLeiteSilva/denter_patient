import 'package:flutter/material.dart';
import 'package:code/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        primarySwatch: Colors.brown,
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
  TextEditingController _controllerName = TextEditingController();
  TextEditingController _controllerTelefone = TextEditingController();

  GlobalKey<FormState> key = GlobalKey();

  CollectionReference _reference =
      FirebaseFirestore.instance.collection('FAZ O L');

  String imageUrl = '';

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
            TextFormField(),
            TextFormField(),
            IconButton(
                onPressed: () async {
                  ImagePicker imagePicker = ImagePicker();
                  XFile? file =
                      await imagePicker.pickImage(source: ImageSource.camera);
                  print('${file?.path}');

                  if (file == null) return;
                  String uniqueFileName =
                      DateTime.now().millisecondsSinceEpoch.toString();

                  Reference referenceRoot = FirebaseStorage.instance.ref();
                  Reference referenceDirImages =
                      referenceRoot.child('emergencies');
                  // pra fazer oq o julio pediu tem que mexer nessa linha de baixo
                  Reference referenceImagetoUpload =
                      referenceDirImages.child(uniqueFileName);
                  try {
                    await referenceImagetoUpload.putFile(File(file.path));

                    imageUrl = await referenceImagetoUpload.getDownloadURL();
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
                  if (key.currentState!.validate()) {
                    String nameClient = _controllerName.text;
                    String celClient = _controllerTelefone.text;

                    Map<String, String> dataToSend = {
                      'nome': nameClient,
                      'telefone': celClient,
                      'foto': imageUrl,
                    };

                    _reference.add(dataToSend);
                  }
                },
                child: const Text('ABRIR CHAMADO'))
          ]),
        ),
      ),
    );
  }
}
