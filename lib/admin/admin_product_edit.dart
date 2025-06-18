import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProductPage extends StatefulWidget {
  final DocumentSnapshot doc;
  const EditProductPage({super.key, required this.doc});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

  List<Map<String, dynamic>> colorOptions = [];
  String? selectedMainCategory;
  String? selectedSubCategory;
  bool isSoldOut = false;

  final Map<String, List<String>> categoryMap = {
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '모닝 루틴': ['모닝 저널', '아로마오일'],
    '운동 용품': ['요가매트', '물병', '운동복'],
  };

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    nameController = TextEditingController(text: data['productName']);
    priceController = TextEditingController(text: data['productPrice'].toString());
    descController = TextEditingController(text: data['description']);
    colorOptions = List<Map<String, dynamic>>.from(data['colors'] ?? []);

    final category = data['productCategory'] ?? {};
    selectedMainCategory = category['main'];
    selectedSubCategory = category['sub'];
    isSoldOut = data['isSoldOut'] ?? false;
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('product_images/${picked.name}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      setState(() {
        colorOptions[index]['imgPath'] = url;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.doc.id)
        .update({
      'productName': nameController.text,
      'productPrice': int.tryParse(priceController.text) ?? 0,
      'description': descController.text,
      'colors': colorOptions,
      'productCategory': {
        'main': selectedMainCategory,
        'sub': selectedSubCategory,
      },
      'isSoldOut': isSoldOut,
    });

    Navigator.pop(context);
  }

  Future<void> _deleteProduct() async {
    await FirebaseFirestore.instance.collection('products').doc(widget.doc.id).delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF819CFF),
        leading: const BackButton(),
        title: const Text('상품 수정', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '상품명'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: '가격'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 5, // ← 설명란 크기 넓힘
              ),
              const SizedBox(height: 12),

              // 🔵 메인 카테고리
              DropdownButtonFormField<String>(
                value: selectedMainCategory,
                items: categoryMap.keys.map((main) {
                  return DropdownMenuItem(
                    value: main,
                    child: Text(main),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMainCategory = val;
                    selectedSubCategory = null;
                  });
                },
                decoration: const InputDecoration(labelText: '메인 카테고리'),
              ),
              const SizedBox(height: 12),

              // 🔹 서브 카테고리
              if (selectedMainCategory != null)
                DropdownButtonFormField<String>(
                  value: selectedSubCategory,
                  items: categoryMap[selectedMainCategory]!
                      .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSubCategory = val;
                    });
                  },
                  decoration: const InputDecoration(labelText: '서브 카테고리'),
                ),
              const SizedBox(height: 12),

              // ❌ 품절 여부
              SwitchListTile(
                title: const Text('품절 여부'),
                value: isSoldOut,
                onChanged: (val) {
                  setState(() {
                    isSoldOut = val;
                  });
                },
              ),

              const SizedBox(height: 20),
              const Text('색상 및 재고'),
              const SizedBox(height: 10),

              ...colorOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final color = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: color['color'],
                          decoration: const InputDecoration(labelText: '색상'),
                          onChanged: (val) => colorOptions[i]['color'] = val,
                        ),
                        TextFormField(
                          initialValue: color['stock'].toString(),
                          decoration: const InputDecoration(labelText: '재고'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => colorOptions[i]['stock'] = int.tryParse(val) ?? 0,
                        ),
                        const SizedBox(height: 8),
                        color['imgPath'] != null
                            ? Image.network(color['imgPath'], height: 100)
                            : const SizedBox(height: 100, child: Placeholder()),
                        TextButton.icon(
                          onPressed: () => _pickImage(i),
                          icon: const Icon(Icons.image),
                          label: const Text('이미지 변경'),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('저장하기'),
              ),
              TextButton(
                onPressed: _deleteProduct,
                child: const Text('삭제하기', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
