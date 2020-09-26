import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: 'Lista',
    debugShowCheckedModeBanner: false,
    home: MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _formKey = GlobalKey<FormState>();
  var _itemController = TextEditingController();
  List<Item> _list = new List<Item>();
  ItemRepository repository = new ItemRepository();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      repository.readData().then((data) {
        setState(() {
          _list = data;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Compras'), centerTitle: true),
      body: Scrollbar(
        child: ListView(
          children: [
            for (int i = 0; i < _list.length; i++)
              ListTile(
                  title: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: _list[i].concluido
                    ? Text(
                        _list[i].nome,
                        style:
                            TextStyle(decoration: TextDecoration.lineThrough),
                      )
                    : Text(_list[i].nome),
                value: _list[i].concluido,
                secondary: IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20.0,
                    color: Colors.red[900],
                  ),
                  onPressed: () {
                    setState(() {
                      _list.removeAt(i);
                      _updateLista();
                      _ordenarLista();
                    });
                  },
                ),
                onChanged: (c) {
                  setState(() {
                    _list[i].concluido = c;
                    _updateLista();
                    _ordenarLista();
                  });
                },
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _displayDialog(context),
      ),
    );
  }

  _updateLista() async {
    repository.saveData(_list);
    _list = await repository.readData();
  }

  _ordenarLista() {
    _list.sort((a, b) {
      if (a.concluido && !b.concluido)
        return 1;
      else if (!a.concluido && b.concluido)
        return -1;
      else
        return 0;
    });
  }

  _displayDialog(context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _itemController,
                validator: (s) {
                  if (s.isEmpty)
                    return "Digite o item.";
                  else
                    return null;
                },
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: "Item"),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: new Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text('SALVAR'),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    setState(() {
                      _list.add(
                          Item(nome: _itemController.text, concluido: false));
                      _updateLista();
                      _ordenarLista();
                      _itemController.text = "";
                    });
                    Navigator.of(context).pop();
                  }
                },
              )
            ],
          );
        });
  }
}

class Item {
  String nome;
  bool concluido;

  Item({this.nome, this.concluido});

  Item.fromJson(Map<String, dynamic> json) {
    nome = json['nome'];
    concluido = json['concluido'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['nome'] = this.nome;
    data['concluido'] = this.concluido;
    return data;
  }
}

class ItemRepository {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.json');
  }

  Future<List<Item>> readData() async {
    try {
      final file = await _localFile;
      // Read the file
      String dataJson = await file.readAsString();

      List<Item> data =
          (json.decode(dataJson) as List).map((i) => Item.fromJson(i)).toList();
      return data;
    } catch (e) {
      return List<Item>();
    }
  }

  Future<bool> saveData(List<Item> list) async {
    try {
      final file = await _localFile;
      final String data = json.encode(list);
      // Write the file
      file.writeAsString(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}
