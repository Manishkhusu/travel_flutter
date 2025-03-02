import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts

class Translatorpg extends StatefulWidget {
  const Translatorpg({Key? key}) : super(key: key);

  @override
  State<Translatorpg> createState() => _TranslatorpgState();
}

class _TranslatorpgState extends State<Translatorpg> {
  final outputcontroller = TextEditingController(text: "result here.........");
  final translator = GoogleTranslator();
  final FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts

  String inputtext = '';
  String inputlanguage = "en";
  String outputlanguage = "fr";

  // Map for language codes to full names
  final Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'ur': 'Urdu',
    'hi': 'Hindi',
    'ne': 'Nepali',
  };

  @override
  void initState() {
    super.initState();
    _initTts(); // Initialize TTS settings
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage(outputlanguage); // Set initial language
    await flutterTts.setPitch(1.0); // Set pitch. Can be changed during runtime
    await flutterTts
        .setSpeechRate(0.5); // Set speed. Can be changed during runtime
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      print("TTS Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS error: ${e.toString()}')),
      );
    }
  }

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
                style: const TextStyle(
                    color: Colors.black), // Add black color for input text
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter text to translate",
                  fillColor: Colors.white,
                  filled: true,
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
                    items: languageNames.entries
                        .map<DropdownMenuItem<String>>((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                  DropdownButton<String>(
                    value: outputlanguage,
                    onChanged: (newValue) {
                      setState(() async {
                        outputlanguage = newValue!;
                        await flutterTts.setLanguage(
                            outputlanguage); // Set TTS language on change
                      });
                    },
                    items: languageNames.entries
                        .map<DropdownMenuItem<String>>((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
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
                style: const TextStyle(
                    color: Colors.black), // Set text color to black
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (Value) {
                  setState(() {
                    inputtext = Value;
                  });
                },
              ),
              const SizedBox(height: 16),
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
      _speak(outputcontroller.text); // Speak immediately after translation
    } catch (e) {
      print("Translation Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: ${e.toString()}')),
      );
    }
  }
}
