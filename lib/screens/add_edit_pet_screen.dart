// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Pantalla per afegir o editar una mascota. Permet fer o seleccionar una foto,
// identificar la raça amb Gemini, pujar la imatge a Firebase Storage i
// desar/actualitzar les dades de la mascota a Cloud Firestore. També disposa
// d’opció per eliminar la mascota i la seva imatge del núvol.
class AddEditPetScreen extends StatefulWidget {
  final Map<String, dynamic>? petData;
  const AddEditPetScreen({super.key, this.petData});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _dataNaixementController =
      TextEditingController();
  final TextEditingController _racaController = TextEditingController();

  final _uuid = const Uuid();

  DateTime? _dataNaixement;
  String? _tipusAnimal = 'gos';
  String? _sexe = '?';
  int _menjarsAlDia = 4;
  XFile? _imatge;
  String? _raca;
  String? _imageUrl;
  String? _tempPetId;
  bool _carregantRaca = false;

  bool get _editant => widget.petData != null;

  @override
  void initState() {
    super.initState();
    if (_editant) {
      final p = widget.petData!;
      _nomController.text = p['name'] ?? '';
      _racaController.text = p['breed'] ?? '';
      final bd = p['birthDate'];
      _dataNaixement = bd is Timestamp ? bd.toDate() : (bd as DateTime?);
      if (_dataNaixement != null) {
        _dataNaixementController.text =
            _dataNaixement!.toLocal().toString().split(' ')[0];
      }
      _tipusAnimal = p['species'] ?? _tipusAnimal;
      _sexe = p['sex'] ?? _sexe;
      _menjarsAlDia = p['dailyFeedGoal'] ?? _menjarsAlDia;
      _imageUrl = p['imageUrl'] as String?;
    }
  }

  // Envia la imatge a Gemini per inferir la raça i retorna la raça o el string “Raça desconeguda”.
  Future<String> _obtenirRaca(File imatge) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) return 'Raça desconeguda';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );
    final base64Image = base64Encode(await imatge.readAsBytes());
    const prompt = '''
Ets un expert en animals. Identifica la raça exacta o més aproximada que puguis del gos o gat que apareix a la imatge.
Dona'm únicament el nom, sense cap altre text ni puntuació.
Si no ho saps, respon exactament així: Raça desconeguda''';
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
    });
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.trim().isNotEmpty) return text.trim();
      }
    } catch (_) {}
    return 'Raça desconeguda';
  }

  // Comprimeix la imatge localment per reduir el pes abans de pujar-la.
  Future<XFile> _comprimeixImatge(XFile imatgeOriginal) async {
    final imatgeComprimida = await FlutterImageCompress.compressAndGetFile(
      imatgeOriginal.path,
      '${imatgeOriginal.path}_compressed.jpg',
      quality: 40,
      minWidth: 700,
      minHeight: 700,
    );
    return imatgeComprimida != null
        ? XFile(imatgeComprimida.path)
        : imatgeOriginal;
  }

  // Puja la imatge comprimida a Firebase Storage i retorna la URL pública.
  Future<String> _pujaImatgeFirebase(XFile imatge, String petId) async {
    final imatgeComprimida = await _comprimeixImatge(imatge);
    final file = File(imatgeComprimida.path);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('users/$uid/pets/$petId.jpg');
    final snap = await ref.putFile(file);
    return await snap.ref.getDownloadURL();
  }

  // Gestiona tot el flux després de triar imatge: pujar-la,
  // obtenir la raça i actualitzar l’estat amb la URL i la raça.
  Future<void> _processaImatge(XFile imatge) async {
    setState(() {
      _imatge = imatge;
      _carregantRaca = true;
      _raca = null;
      _racaController.text = '';
    });
    final petId =
        _editant
            ? widget.petData!['id'] as String
            : (_tempPetId ??= _uuid.v4());
    final racaF = _obtenirRaca(File(imatge.path));
    final uploadF = _pujaImatgeFirebase(XFile(imatge.path), petId);
    final results = await Future.wait([racaF, uploadF]);
    if (!mounted) return;
    setState(() {
      _carregantRaca = false;
      _raca = results[0];
      _racaController.text = _raca!;
      _imageUrl = results[1];
    });
  }

  // Mostra un bottom-sheet per escollir càmera o galeria i inicia la selecció d’imatge.
  void _seleccionaImatge() {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Fer foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final imatge = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (imatge != null) _processaImatge(imatge);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galeria'),
                onTap: () async {
                  Navigator.pop(context);
                  final imatge = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (imatge != null) _processaImatge(imatge);
                },
              ),
            ],
          ),
    );
  }

  // Valida el formulari, puja imatge si cal i crea/actualitza el document de la mascota a Firestore.
  Future<void> _desaMascota() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final petId =
        _editant ? widget.petData!['id'] as String : (_tempPetId ?? _uuid.v4());
    final dadesBase = <String, dynamic>{
      'id': petId,
      'name': _nomController.text.trim(),
      'breed': _raca ?? _racaController.text.trim(),
      'birthDate':
          _dataNaixement == null ? null : Timestamp.fromDate(_dataNaixement!),
      'species': _tipusAnimal,
      'sex': _sexe,
      'dailyFeedGoal': _menjarsAlDia,
    }..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

    String? urlImatge = _imageUrl;
    if (_imatge != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Pujant la imatge al núvol...',
                      style: AppTextStyles.midText(context),
                    ),
                  ),
                ],
              ),
            ),
      );
      urlImatge = await _pujaImatgeFirebase(XFile(_imatge!.path), petId);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    final dades = {...dadesBase, 'imageUrl': urlImatge};

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets');
    if (_editant) {
      await col.doc(petId).update(dades);
    } else {
      await col.doc(petId).set({
        ...dades,
        'dailyFeedCount': 0,
        'lastFeed': DateTime.now(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context, _editant ? {...widget.petData!, ...dades} : true);
  }

  // Elimina la foto de Storage i el document de la mascota a Firestore.
  Future<void> _eliminaMascota() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = widget.petData!['id'] as String;

    try {
      await FirebaseStorage.instance.ref('users/$uid/pets/$id.jpg').delete();
    } catch (_) {}

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(id)
        .delete();

    if (mounted) Navigator.pop(context, {'deleted': true, 'id': id});
  }

  // Mostra un diàleg de confirmació i, si s’accepta, crida _eliminaMascota().
  Future<void> _confirmaElimina() async {
    final res = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar mascota'),
            content: const Text('Segur que vols eliminar aquesta mascota?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel·lar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (res == true) _eliminaMascota();
  }

  // Construeix un botó circular reutilitzable (icona + estat seleccionat).
  Widget _botoCircular({
    required IconData icona,
    required bool seleccionat,
    required VoidCallback onTap,
    required double radius,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor:
            seleccionat ? AppColors.primary : AppColors.backgroundComponent,
        child: Icon(
          icona,
          color: seleccionat ? Colors.white : Colors.black,
          size: iconSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme.copyWith(
      labelStyle: const TextStyle(color: AppColors.primary),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: inputDecorationTheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withAlpha((255 * 0.4).toInt()),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            _editant ? 'Editar mascota' : 'Afegir mascota',
            style: AppTextStyles.titleText(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(screenHeight * 0.008),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundComponent,
                    borderRadius: BorderRadius.circular(screenHeight * 0.015),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(screenHeight * 0.015),
                    onTap: _seleccionaImatge,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHeight * 0.02,
                        vertical: screenHeight * 0.015,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback:
                                (b) => AppColors.gradient.createShader(b),
                            child: Icon(
                              _imatge == null && _imageUrl == null
                                  ? Icons.add_a_photo
                                  : Icons.check_circle,
                              size: screenHeight * 0.03,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: screenHeight * 0.01),
                          ShaderMask(
                            shaderCallback:
                                (b) => AppColors.gradient.createShader(b),
                            child: Text(
                              _imatge == null && _imageUrl == null
                                  ? 'Afegir imatge'
                                  : 'Imatge afegida',
                              style: AppTextStyles.primaryText(
                                context,
                              ).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_imatge != null || _imageUrl != null) ...[
                            SizedBox(width: screenHeight * 0.015),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                screenHeight * 0.01,
                              ),
                              child:
                                  _imatge != null
                                      ? Image.file(
                                        File(_imatge!.path),
                                        width: screenHeight * 0.06,
                                        height: screenHeight * 0.06,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        _imageUrl!,
                                        width: screenHeight * 0.06,
                                        height: screenHeight * 0.06,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.0125),
                if (_carregantRaca) ...[
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Detectant raça amb IA.'),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                ] else if (_editant || _raca != null) ...[
                  TextField(
                    controller: _racaController,
                    decoration: const InputDecoration(
                      labelText: 'Raça detectada',
                      suffixIcon: Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.0125),
                ],
                TextField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                SizedBox(height: screenHeight * 0.008),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dataNaixement ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _dataNaixement = picked;
                        _dataNaixementController.text =
                            _dataNaixement!.toLocal().toString().split(' ')[0];
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dataNaixementController,
                      decoration: const InputDecoration(
                        labelText: 'Data de naixement',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                Text('Animal:', style: AppTextStyles.midText(context)),
                SizedBox(height: screenHeight * 0.0125),
                Row(
                  children: [
                    _botoCircular(
                      icona: FontAwesomeIcons.dog,
                      seleccionat: _tipusAnimal == 'gos',
                      onTap: () => setState(() => _tipusAnimal = 'gos'),
                      radius: screenHeight * 0.035,
                      iconSize: screenHeight * 0.03,
                    ),
                    SizedBox(width: screenHeight * 0.01),
                    _botoCircular(
                      icona: FontAwesomeIcons.cat,
                      seleccionat: _tipusAnimal == 'gat',
                      onTap: () => setState(() => _tipusAnimal = 'gat'),
                      radius: screenHeight * 0.035,
                      iconSize: screenHeight * 0.03,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.0125),
                Text('Sexe:', style: AppTextStyles.midText(context)),
                SizedBox(height: screenHeight * 0.0125),
                Row(
                  children: [
                    _botoCircular(
                      icona: FontAwesomeIcons.mars,
                      seleccionat: _sexe == 'M',
                      onTap: () => setState(() => _sexe = 'M'),
                      radius: screenHeight * 0.035,
                      iconSize: screenHeight * 0.03,
                    ),
                    SizedBox(width: screenHeight * 0.01),
                    _botoCircular(
                      icona: FontAwesomeIcons.venus,
                      seleccionat: _sexe == 'F',
                      onTap: () => setState(() => _sexe = 'F'),
                      radius: screenHeight * 0.035,
                      iconSize: screenHeight * 0.03,
                    ),
                    SizedBox(width: screenHeight * 0.01),
                    _botoCircular(
                      icona: FontAwesomeIcons.question,
                      seleccionat: _sexe == '?',
                      onTap: () => setState(() => _sexe = '?'),
                      radius: screenHeight * 0.035,
                      iconSize: screenHeight * 0.03,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.0125),
                Text('Menjars:', style: AppTextStyles.midText(context)),
                SizedBox(height: screenHeight * 0.0125),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        thumbColor: AppColors.primary,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.backgroundComponent,
                        value: _menjarsAlDia.toDouble(),
                        min: 1,
                        max: 8,
                        divisions: 7,
                        label: '$_menjarsAlDia menjars',
                        onChanged:
                            (val) =>
                                setState(() => _menjarsAlDia = val.toInt()),
                      ),
                    ),
                    Text(
                      '$_menjarsAlDia menjars / dia',
                      style: AppTextStyles.tinyText(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Material(
                  borderRadius: BorderRadius.circular(screenHeight * 0.015),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(screenHeight * 0.015),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(screenHeight * 0.015),
                      onTap: _desaMascota,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        child: Center(
                          child: Text(
                            _editant ? 'Guardar' : 'Afegir mascota',
                            style: AppTextStyles.bigText(context).copyWith(
                              color: Colors.white,
                              fontSize: screenHeight * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_editant) ...[
                  SizedBox(height: screenHeight * 0.02),
                  Material(
                    borderRadius: BorderRadius.circular(screenHeight * 0.015),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          screenHeight * 0.015,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          screenHeight * 0.015,
                        ),
                        onTap: _confirmaElimina,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.02,
                          ),
                          child: Center(
                            child: Text(
                              'Eliminar mascota',
                              style: AppTextStyles.bigText(context).copyWith(
                                color: Colors.white,
                                fontSize: screenHeight * 0.03,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
