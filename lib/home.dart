// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:excel/excel.dart';



class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  // this is a git comment

  Future<void> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    setState(() => _user = userCredential.user);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Auth')),
      body: Center(
        child: _user == null
            ? ElevatedButton(onPressed: _signInWithGoogle, child: Text('Sign in with Google'))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Signed in as ${_user!.displayName}'),
            ElevatedButton(onPressed: _signOut, child: Text('Sign out')),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DataScreen())), child: Text('Go to Data Management')),
          ],
        ),
      ),
    );
  }
}

class DataScreen extends StatelessWidget {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _controller = TextEditingController();

  Future<void> _addData() async {
    await _db.collection('data').add({'content': _controller.text});
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      await _storage.ref('uploads/${result.files.single.name}').putFile(file);
    }
  }

  Future<void> _uploadUsersFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          String name = row[0]?.value.toString() ?? '';
          String email = row[1]?.value.toString() ?? '';
          if (name.isNotEmpty && email.isNotEmpty) {
            await _db.collection('users').add({'name': name, 'email': email});
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Management')),
      body: Column(
        children: [
          TextField(controller: _controller, decoration: InputDecoration(labelText: 'Enter Data')),
          ElevatedButton(onPressed: _addData, child: Text('Add Data')),
          ElevatedButton(onPressed: _uploadFile, child: Text('Upload File')),
          ElevatedButton(onPressed: _uploadUsersFromExcel, child: Text('Upload Users from Excel')),
        ],
      ),
    );
  }
}
