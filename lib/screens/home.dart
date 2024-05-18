import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Origin Styles Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Category',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('category').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading");
                }
                return Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView(
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Details(
                                      docID: document.id,
                                    )),
                          );
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Text(document.id),
                          ), // Use document.id to get the document name
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Details extends StatefulWidget {
  String docID;
  Details({super.key, required this.docID});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Origin Styles Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("T-Shirts",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AddTShirtDialog(docID: widget.docID);
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded)),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('category')
                  .doc(widget.docID)
                  .collection('tshirts')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading");
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot tshirt = snapshot.data!.docs[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Image.network(tshirt['image']),
                              ),
                              Text(tshirt['title']),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddTShirtDialog extends StatefulWidget {
  final String docID;

  AddTShirtDialog({required this.docID});

  @override
  _AddTShirtDialogState createState() => _AddTShirtDialogState();
}

class _AddTShirtDialogState extends State<AddTShirtDialog> {
  Uint8List? _imageFile;

  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController();
  final _imageController = TextEditingController();
  final _orgPriceController = TextEditingController();
  final _priceController = TextEditingController();
  final _titleController = TextEditingController();

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        final ref =
            FirebaseStorage.instance.ref().child(widget.docID).child(file.name);

        final uploadTask = ref.putData(file.bytes!);

        await uploadTask.whenComplete(() async {
          final downloadUrl = await ref.getDownloadURL();
          _imageController.text = downloadUrl;
        });

        setState(() {
          _imageFile = file.bytes!;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add T-Shirt'),
      content: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: _pickAndUploadImage,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: _imageFile == null
                      ? const Icon(Icons.upload_file)
                      : SizedBox(
                          height: 200,
                          width: 100,
                          child: Image.memory(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(labelText: 'Discount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a discount';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _orgPriceController,
              decoration: const InputDecoration(labelText: 'Original Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an original price';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              FirebaseFirestore.instance
                  .collection('category')
                  .doc(widget.docID)
                  .collection('tshirts')
                  .add({
                'discount': int.parse(_discountController.text),
                'image': _imageController.text,
                'org_price': int.parse(_orgPriceController.text),
                'price': int.parse(_priceController.text),
                'ratings': 5,
                'reviews':
                    [], // You may need to parse this depending on the data structure
                'status': true,
                'title': _titleController.text,
              });
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
