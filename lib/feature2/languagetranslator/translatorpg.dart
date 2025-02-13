import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Translatorpg extends StatefulWidget {
  const Translatorpg({Key? key}) : super(key: key);

  @override
  State<Translatorpg> createState() => _TranslatorpgState();
}

enum TtsState { playing, stopped, paused, continued }

class _TranslatorpgState extends State<Translatorpg> {
  final outputcontroller = TextEditingController(text: "result here.........");
  final translator = GoogleTranslator();
  FlutterTts flutterTts = FlutterTts();

  String inputtext = '';
  String inputlanguage = "en";
  String outputlanguage = "fr";

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool get doHalt => false; // Add halt option

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<void> initTts() async {
    print("Initializing TTS...");
    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("Error: $msg");
        ttsState = TtsState.stopped;
      });
    });

    try {
      await flutterTts.awaitSpeakCompletion(true); // Wait until its done
      await flutterTts.setLanguage(outputlanguage);
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      print('TTS initialized successfully.');
    } catch (e) {
      print("Error initializing TTS: $e");
    }
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
        _speak(); // Speak the translated text immediately
      });
    } catch (e) {
      print("Translation Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: ${e.toString()}')),
      );
    }
  }

  Future<void> _speak() async {
    if (outputcontroller.text.isNotEmpty) {
      try {
        if (ttsState == TtsState.playing) {
          print("Stopping TTS...");
          var result = await flutterTts.stop();
          if (result == 1) {
            setState(() => ttsState = TtsState.stopped);
          }
        }
        print("Speaking: ${outputcontroller.text}");

        var result = await flutterTts.speak(outputcontroller.text);
        if (result == 1) {
          setState(() => ttsState = TtsState.playing);
        }
      } catch (e) {
        print("TTS Speaking Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS Speaking Error: ${e.toString()}')),
        );
      }
    } else {
      print("No text to speak.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to speak.')),
      );
    }
  }

  Future<void> _setTtsLanguage(String language) async {
    try {
      await flutterTts.setLanguage(language);
    } catch (e) {
      print('Error setting TTS language: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting TTS language: ${e.toString()}')),
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
                        _setTtsLanguage(newValue); // Change TTS language
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: _speak,
                    tooltip: 'Speak',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
