
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:code/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

import 'maps.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Geolocator.requestPermission();
  await signInAnon();
  runApp(const MyApp());
}
Future<void> signInAnon() async {
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

  List<File> selectedImages = [];
  List<String> imageNames = [];

  bool _isButtonEnabled = false;


  void _checkFields() {
    if (_controllerName.text.isNotEmpty && _controllerTelefone.text.isNotEmpty) {
      setState(() {
        _isButtonEnabled = true;
      });
    } else {
      setState(() {
        _isButtonEnabled = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _controllerName.addListener(_checkFields);
    _controllerTelefone.addListener(_checkFields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        toolbarHeight: 30,
        backgroundColor: const Color(0xFF145248),
      ) ,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sign_in_up.png'),
            fit: BoxFit.cover,
          )
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            key: key,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _controllerName,
                      decoration:  InputDecoration(
                        hintText: 'Informe o nome',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                    ),

                  ),

                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),

                  child: TextFormField(
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TelefoneInputFormatter(),
                    ],
                    maxLength: 13,
                    controller: _controllerTelefone,
                    decoration:  InputDecoration(
                      hintText: 'Informe o telefone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF145248),
                      ),
                      onPressed:_takeMultiplePhotos,

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance),
                          SizedBox(width: 8),
                          Text("Tirar Foto")
                        ],
                      ),
                    ),
                  ),
                ),
                if (selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFF145248),
                        ),
                        onPressed: _openImageDialog,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_album),
                            SizedBox(width: 8),
                            Text("Ver Fotos")
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF145248),
                      ),
                      onPressed:(_controllerName.text.isEmpty || _controllerTelefone.text.isEmpty) ? null : (){
                        _openChamado();
                      },

                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag),
                          SizedBox(width: 7),
                          Text("Emergência")
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takeMultiplePhotos() async {
    ImagePicker imagePicker = ImagePicker();
    for (int i = 0; i < 3; i++) {
      XFile? file = await imagePicker.pickImage(source: ImageSource.camera);
      if (file != null) {
        selectedImages.add(File(file.path));
      }
    }
    setState(() {});
  }

  void _openImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                for (var image in selectedImages)
                  Container(
                    margin: EdgeInsets.only(bottom: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    child: Image.file(image),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openChamado() async {
    // Solicitar permissões de localização
    await _requestLocationPermission();

    // Verificar se as permissões de localização foram concedidas
    if (await Geolocator.isLocationServiceEnabled() &&
        await Geolocator.checkPermission() == LocationPermission.whileInUse) {
      // Obter a localização atual
      Position position = await Geolocator.getCurrentPosition();

      // Utilize a posição como necessário
      double latitude = position.latitude;
      double longitude = position.longitude;
      GeoPoint location = GeoPoint(latitude, longitude);

      final User? user = auth.currentUser;
      final uid = user!.uid;
      if (key.currentState!.validate()) {
        String nameClient = _controllerName.text;
        String celClient = _controllerTelefone.text;
        EasyLoading.show(status: 'loading...');
        final fcmToken = await FirebaseMessaging.instance.getToken();
        List<String> imagesData = [];
        for (int i = 0; i < selectedImages.length; i++) {
          String uniqueFileName =
          DateTime.now().millisecondsSinceEpoch.toString();
          Reference referenceRoot = FirebaseStorage.instance.ref();
          Reference referenceDirImages = referenceRoot.child('emergencies');
          Reference referenceImageToUpload =
          referenceDirImages.child(uniqueFileName);

          await referenceImageToUpload.putFile(selectedImages[i]);


          String imageName = uniqueFileName;


          imageNames.add(imageName);

          imagesData.add(imageName);
        }

        Map<String, dynamic> dataToSend = {
          'uid': uid,
          'name': nameClient,
          'phone': celClient,
          'photos': imagesData,
          'fcmToken': fcmToken,
          'status': 'new',
          'location': location,
        };
        _reference.doc(uid).set(dataToSend);

        EasyLoading.dismiss();
        EasyLoading.showSuccess("complete");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyListScreen(),
          ),
        );
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As permissões de localização foram negadas.'),
        ),
      );
    } else if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'As permissões de localização foram negadas permanentemente. Abra as configurações do aplicativo para conceder permissão.'),
        ),
      );
    }
  }

}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;

    String formattedText = '';
    int cursorOffset = 0;

    if (newTextLength >= 3) {
      formattedText += newValue.text.substring(0, 2) + ' ';
      if (newValue.selection.end >= 2) selectionIndex++;
    }

    if (newTextLength >= 8) {
      formattedText += newValue.text.substring(2, 7) + '-';
      if (newValue.selection.end >= 7) selectionIndex++;
    }

    if (newTextLength >= 13) {
      formattedText += newValue.text.substring(7, 13);
      if (newValue.selection.end >= 13) selectionIndex += 2;
    } else {
      formattedText += newValue.text.substring(7);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: selectionIndex,
      ),
    );
  }
}


class EmergencyListScreen extends StatelessWidget {
  String? getCurrentUserID() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    return null; // Retorna null se o usuário não estiver autenticado
  }
  Future<void> updateStatus(String status,String uidDentist) async {
    try {
      String? currentUserID = getCurrentUserID();
      var documentRef = FirebaseFirestore.instance.collection('emergency').doc(currentUserID);

      await documentRef.update({'status': status,'uidDentist': uidDentist,});
      print('Documento atualizado com sucesso!');
    } catch (error) {
      print('Erro ao atualizar o documento: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserID = getCurrentUserID();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Aceites'),
        backgroundColor: Color(0xFF145248),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency')
            .doc(currentUserID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Nenhum item de emergência encontrado.'));
          }
          var emergencyData = snapshot.data!.data() as Map<String, dynamic>;
          var status = emergencyData['status'] as String?;

          if (status != 'draft') {
            return Center(child: Text('Aguardando dentistas...'));
          }

          var acceptDentistList = emergencyData['acceptDentistList'] as Map<String, dynamic>;

          return ListView.builder(
            itemCount: acceptDentistList.length,
            itemBuilder: (context, index) {
              var acceptDentistData = acceptDentistList.values.toList()[index] as Map<String, dynamic>;

              // Utilize os dados individuais do mapa de mapas para exibição na lista
              return ListTile(
                title: Text(acceptDentistData['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        var acceptDentistData = acceptDentistList.values.toList()[index] as Map<String, dynamic>;
                        var uidDentist = acceptDentistData['uid'];

                        updateStatus('inProcess',uidDentist);

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EmergencyScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.green),
                      child: Text('Aceitar'),
                    ),
                    SizedBox(width: 8),
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

class EmergencyScreen extends StatelessWidget {
  String? getCurrentUserID() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    return null; // Retorna null se o usuário não estiver autenticado
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserID = getCurrentUserID();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency')
          .doc(currentUserID)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          var emergencyData = snapshot.data!;
          var status = emergencyData['status'];

          Widget content;
          if (status == 'inProcess') {
            content = Text('Em Atendimento');
          } else if (status == 'finished') {
            content = ElevatedButton(
              onPressed: () {
                // Ação quando o botão "Avaliar Atendimento" for pressionado
              },
              style: ElevatedButton.styleFrom(primary: Colors.teal[900]),
              child: Text('Avaliar Atendimento'),
            );
          } else {
            // Status desconhecido ou inválido
            content = Text('Status Desconhecido');
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Detalhes de Emergência'),
              backgroundColor: Color(0xFF145248),
            ),
            body: Center(child: content),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Detalhes de Emergência'),
              backgroundColor: Color(0xFF145248),
            ),
            body: Center(child: Text('Erro ao carregar os dados')),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Detalhes de Emergência'),
              backgroundColor: Color(0xFF145248),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
