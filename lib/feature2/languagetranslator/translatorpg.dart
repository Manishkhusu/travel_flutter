import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class Translatorpg extends StatefulWidget {
  const Translatorpg({Key? key}) : super(key: key);

  @override
  State<Translatorpg> createState() => _TranslatorpgState();
}

class _TranslatorpgState extends State<Translatorpg> {
  final outputcontroller = TextEditingController(text: "result here.........");
  final translator = GoogleTranslator();

  String inputtext = '';
  String inputlanguage = "en";
  String outputlanguage = "fr";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Translator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29ABE2),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFE1F5FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter text to translate",
                ),
                onChanged: (Value) {
                  setState(() {
                    inputtext = Value;
                  });
                },
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(
                    value: inputlanguage,
                    onChanged: (newValue) {
                      setState(() {
                        inputlanguage = newValue!;
                      });
                    },
                    items: const <String>[
                      'en',
                      'fr',
                      'es',
                      'de',
                      'ur',
                      'hi',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                  DropdownButton<String>(
                    value: outputlanguage,
                    onChanged: (newValue) {
                      setState(() {
                        outputlanguage = newValue!;
                      });
                    },
                    items: const <String>[
                      'en',
                      'fr',
                      'es',
                      'de',
                      'ur',
                      'hi',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                ),
                child: const Text("Translate"),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: outputcontroller,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (Value) {
                  setState(() {
                    inputtext = Value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> translateText() async {
    try {
      final translated = await translator.translate(
        inputtext,
        from: inputlanguage,
        to: outputlanguage,
      );
      setState(() {
        outputcontroller.text = translated.text;
      });
    } catch (e) {
      print("Translation Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: ${e.toString()}')),
      );
    }
  }
}
