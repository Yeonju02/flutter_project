import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
    '전체': [],
    '수면 용품': ['수면 안대', '숙면베개', '무드등'],
    '생활 용품': ['다이어리', '디퓨저', '마스크팩'],
    '운동 용품': ['운동기구', '물병', '운동복'],
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

    await FirebaseFirestore.instance.collection('products').doc(widget.doc.id).update({
      'productName': nameController.text,
      'productPrice': int.tryParse(priceController.text) ?? 0,
      'description': descController.text,
      'colors': colorOptions,
      'productCategory': {'main': selectedMainCategory, 'sub': selectedSubCategory},
      'isSoldOut': isSoldOut,
    });

    Navigator.pop(context);
  }

  Future<void> _deleteProduct() async {
    await FirebaseFirestore.instance.collection('products').doc(widget.doc.id).delete();
    Navigator.pop(context);
  }

  InputDecoration _inputStyle(String hint) {
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
        title: const Text('상품 수정', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('상품명', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(controller: nameController, decoration: _inputStyle('상품명')),
              const SizedBox(height: 12),
              const Text('가격', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: priceController,
                decoration: _inputStyle('가격'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('설명', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descController,
                decoration: _inputStyle('설명'),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              const Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField2<String>(
                isExpanded: true,
                decoration: _inputStyle('메인 카테고리'),
                value: selectedMainCategory,
                hint: const Text('메인 카테고리'),
                items: categoryMap.keys.map((main) {
                  return DropdownMenuItem(value: main, child: Text(main));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedMainCategory = val;
                    selectedSubCategory = null;
                  });
                },
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),
              if (selectedMainCategory != null)
                DropdownButtonFormField2<String>(
                  isExpanded: true,
                  decoration: _inputStyle('서브 카테고리'),
                  value: selectedSubCategory,
                  hint: const Text('서브 카테고리'),
                  items: categoryMap[selectedMainCategory]!
                      .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSubCategory = val),
                  dropdownStyleData: DropdownStyleData(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('품절 여부'),
                value: isSoldOut,
                onChanged: (val) => setState(() => isSoldOut = val),
                activeColor: const Color(0xFFA5C8F8),          // ON thumb
                activeTrackColor: const Color(0xFFBBD6F5),     // ON track
                inactiveThumbColor: const Color(0xFFA5C8F8),   // OFF thumb
                inactiveTrackColor: const Color(0xFFEAF2FF),   // OFF track (연한 파랑)
              ),
              const SizedBox(height: 20),
              const Text('색상 및 재고', style: TextStyle(fontWeight: FontWeight.bold),),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA5C8F8)),
                child: const Text('저장하기', style: TextStyle(color: Colors.white),),
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