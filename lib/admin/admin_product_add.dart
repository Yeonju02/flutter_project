import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String? selectedMainCategory;
  String? selectedSubCategory;
  bool isUploading = false;

  final Map<String, List<String>> categoryMap = {
    '모닝 루틴': ['모닝 저널', '아로마오일'],
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '운동 용품': ['요가매트', '물병', '운동복'],
    '기타': ['기타']
  };

  List<Map<String, dynamic>> colorVariants = [
    {'color': TextEditingController(), 'stock': TextEditingController(), 'image': null},
  ];

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        colorVariants[index]['image'] = pickedFile;
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (colorVariants.any((variant) => variant['image'] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("각 색상에 이미지가 필요합니다.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      List<Map<String, dynamic>> colorList = [];

      for (final variant in colorVariants) {
        final uuid = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref().child('product_images/$uuid.jpg');
        await ref.putFile(File(variant['image'].path));
        final imgUrl = await ref.getDownloadURL();

        colorList.add({
          'color': variant['color'].text.trim(),
          'stock': int.parse(variant['stock'].text.trim()),
          'imgPath': imgUrl,
        });
      }

      await FirebaseFirestore.instance.collection('products').add({
        'productName': nameController.text.trim(),
        'productPrice': int.parse(priceController.text.trim()),
        'description': descController.text.trim(),
        'productCategory': {
          'main': selectedMainCategory,
          'sub': selectedSubCategory
        },
        'colors': colorList,
        'isSoldOut': false,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: \$e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF819CFF),
        leading: const BackButton(),
        title: const Text('상품 추가', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Product name'),
                validator: (value) => value!.isEmpty ? '상품명을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(hintText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? '가격을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Description'),
                validator: (value) => value!.isEmpty ? '설명을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMainCategory,
                hint: const Text('Main Category'),
                items: categoryMap.keys
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMainCategory = val;
                    selectedSubCategory = null;
                  });
                },
                validator: (value) => value == null ? '대분류를 선택하세요' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSubCategory,
                hint: const Text('Sub Category'),
                items: (selectedMainCategory != null)
                    ? categoryMap[selectedMainCategory]!
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList()
                    : [],
                onChanged: (val) {
                  setState(() {
                    selectedSubCategory = val;
                  });
                },
                validator: (value) => value == null ? '소분류를 선택하세요' : null,
              ),
              const SizedBox(height: 20),
              const Text('색상/재고/이미지 등록', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: List.generate(colorVariants.length, (index) {
                  final colorCtrl = colorVariants[index]['color'] as TextEditingController;
                  final stockCtrl = colorVariants[index]['stock'] as TextEditingController;
                  final image = colorVariants[index]['image'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: colorCtrl,
                            decoration: const InputDecoration(hintText: 'Color'),
                            validator: (value) => value!.isEmpty ? '색상을 입력하세요' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: stockCtrl,
                            decoration: const InputDecoration(hintText: 'Stock'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? '재고를 입력하세요' : null,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _pickImage(index),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: image == null
                                    ? const Icon(Icons.camera_alt)
                                    : Image.file(File(image.path), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (colorVariants.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    colorVariants.removeAt(index);
                                  });
                                },
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    colorVariants.add({
                      'color': TextEditingController(),
                      'stock': TextEditingController(),
                      'image': null,
                    });
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('색상 추가'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isUploading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}