import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();

  String? selectedMainCategory;
  String? selectedSubCategory;
  bool isUploading = false;

  final Map<String, List<String>> categoryMap = {
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '생활 용품': ['다이어리', '디퓨저', '마스크팩'],
    '운동 용품': ['운동기구', '물병', '운동복']
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
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F4FA),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              const Text('상품명', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('상품명을 입력하세요'),
                validator: (value) => value!.isEmpty ? '상품명을 입력하세요' : null,
              ),
              const SizedBox(height: 12),

              const Text('가격', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: priceController,
                decoration: _inputDecoration('가격을 입력하세요'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? '가격을 입력하세요' : null,
              ),
              const SizedBox(height: 12),

              const Text('상품 설명', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descController,
                decoration: _inputDecoration('상품 설명을 입력하세요'),
                validator: (value) => value!.isEmpty ? '상품 설명을 입력하세요' : null,
              ),
              const SizedBox(height: 12),

              const Text('카테고리 선택', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField2<String>(
                isExpanded: true,
                value: selectedMainCategory,
                decoration: _inputDecoration('대분류를 선택하세요'),
                hint: const Text('대분류'),
                items: categoryMap.keys.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMainCategory = val;
                    selectedSubCategory = null;
                  });
                },
                validator: (value) => value == null ? '대분류를 선택하세요' : null,
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: _inputDecoration('소분류를 선택하세요'),
                value: selectedSubCategory,
                hint: const Text('소분류'),
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
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
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
                  backgroundColor: const Color(0xFFA5C8F8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('상품 등록', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
