import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/tagihan_item.dart';

class PaymentAddItem extends StatefulWidget {
  final List<TagihanItem> tagihanItems;
  final String tagihanName;
  PaymentAddItem({
    super.key,
    required this.tagihanItems,
    required this.tagihanName,
  });
  @override
  State<PaymentAddItem> createState() =>
      _PaymentAddItemState();
}

class _PaymentAddItemState extends State<PaymentAddItem> {
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<TextEditingController> _priceControllers = [];
  final _tagihanNameController = TextEditingController();

  final List<TagihanItem> _tagihanItems = [];

  void _submitItem() {
    if (_formKey.currentState!.validate()) {
      final List<TagihanItem> result = [];

      for (int i = 0; i < _tagihanItems.length; i++) {
        result.add(
          TagihanItem(
            name: _nameControllers[i].text,
            description: _descriptionControllers[i].text,
            price:
                int.tryParse(_priceControllers[i].text) ??
                0,
          ),
        );
      }

      context.pop(result); // Return all items
    }
  }

  void _addItem() {
    setState(() {
      _tagihanItems.add(
        TagihanItem(name: '', description: '', price: 0),
      );
      _nameControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _priceControllers.add(
        TextEditingController(text: 0.toString()),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _tagihanNameController.text = widget.tagihanName;
    if (widget.tagihanItems.isEmpty) {
      _tagihanItems.add(
        TagihanItem(name: '', description: '', price: 0),
      );
      _nameControllers.add(TextEditingController(text: ''));
      _descriptionControllers.add(
        TextEditingController(text: ''),
      );
      _priceControllers.add(
        TextEditingController(text: 0.toString()),
      );
    } else {
      _tagihanItems.addAll(widget.tagihanItems);
      for (var item in _tagihanItems) {
        _nameControllers.add(
          TextEditingController(text: item.name),
        );
        _descriptionControllers.add(
          TextEditingController(text: item.description),
        );
        _priceControllers.add(
          TextEditingController(
            text: item.price.toString(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Tagihan '),
              SizedBox(height: 8),
              TextFormField(
                controller: _tagihanNameController,
                readOnly: true,
                decoration: _inputDecoration(),
              ),
              SizedBox(height: 12),
              Text('Rincian'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _tagihanItems.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Nama Tagihan
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller:
                                    _nameControllers[index],
                                decoration:
                                    _inputDecoration(),
                                validator:
                                    (value) =>
                                        value == null ||
                                                value
                                                    .isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Total Pembayaran
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller:
                                    _priceControllers[index],
                                keyboardType:
                                    TextInputType.number,
                                decoration:
                                    _inputDecoration(),
                                validator:
                                    (value) =>
                                        value == null ||
                                                value
                                                    .isEmpty
                                            ? 'Required'
                                            : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Trash Icon Button
                        if (_tagihanItems.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _tagihanItems.removeAt(
                                  index,
                                );
                                _nameControllers.removeAt(
                                  index,
                                );
                                _descriptionControllers
                                    .removeAt(index);
                                _priceControllers.removeAt(
                                  index,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors
                          .transparent, // Remove background
                  elevation: 0, // Remove shadow
                  foregroundColor:
                      Colors.blue, // Text color (optional)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.blue, // Blue border
                      width: 1.5,
                    ),
                  ),
                ),
                icon: Icon(Icons.add),
                label: Text("Add Item"),
              ),
              SizedBox(height: 12),
              Divider(),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text(
                    'Rp. ${_tagihanItems.fold(0, (sum, item) => sum + item.price).toString()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue, // Remove background
                    elevation: 0, // Text color (optional)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.black, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.black, width: 1),
    ),
  );
}
