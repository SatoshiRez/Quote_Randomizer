import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

void main() => runApp(const QuoteApp());

class QuoteApp extends StatelessWidget {
  const QuoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.pinkAccent,
        fontFamily: 'Roboto',
      ),
      home: const QuoteScreen(),
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});
  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  String _quote = "Ready for some lovely words?\nTap the button below!";
  String _author = "Satoshi";
  bool _isComputing = false;

  // Cache the file so we don't reload it from memory on every single tap
  ByteData? _csvData;

  // The lag-free background worker
  static Map<String, String> _processFile(ByteData data) {
    final int totalSize = data.lengthInBytes;
    // Safely determine chunk size (avoid negative numbers)
    final int chunkSize = totalSize > 4096 ? 4096 : totalSize;

    // Try multiple times to guarantee we find a quote that is SHORT enough
    for (int attempt = 0; attempt < 10; attempt++) {
      final int randomStart = totalSize > chunkSize ? Random().nextInt(totalSize - chunkSize) : 0;

      final Uint8List bytes = data.buffer.asUint8List(randomStart, chunkSize);
      final String chunk = utf8.decode(bytes, allowMalformed: true);

      List<String> lines = chunk.split('\n');

      // We skip the first and last line of the chunk because they might be cut off halfway
      for (int i = 1; i < lines.length - 1; i++) {
        String csvLine = lines[i].trim();
        if (csvLine.isEmpty) continue;

        List<List<dynamic>> rows = const CsvToListConverter().convert(csvLine);
        if (rows.isNotEmpty && rows[0].isNotEmpty) {
          String parsedQuote = rows[0][0].toString();

          // FILTER: Only accept quotes shorter than 160 characters!
          if (parsedQuote.length <= 160) {
            return {
              'quote': parsedQuote,
              'author': rows[0].length > 1 ? rows[0][1].toString() : "Unknown"
            };
          }
        }
      }
    }
    return {'quote': 'Oops, couldn\'t find a short quote this time! Try again 🌸', 'author': ''};
  }

  Future<void> _fetchQuoteLagFree() async {
    setState(() => _isComputing = true);

    try {
      // Load file only once to improve performance
      _csvData ??= await rootBundle.load("assets/quotes.csv");
      final Map<String, String> result = await compute(_processFile, _csvData!);

      setState(() {
        _quote = result['quote']!;
        _author = result['author']!;
      });
    } catch (e) {
      setState(() => _quote = "Oh no! Couldn't read the quotes file 🥺");
    } finally {
      setState(() => _isComputing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "🌸 Welcome 🌸",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1EB), Color(0xFFACE0F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                        decoration: BoxDecoration(
                          // FIX 1: Replaced withOpacity with withValues(alpha: ...)
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              // FIX 2: Replaced withOpacity with withValues(alpha: ...)
                              color: Colors.pinkAccent.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _quote,
                                key: ValueKey<String>(_quote),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _author.isNotEmpty && _author != "Unknown" ? "~ $_author ~" : "",
                                key: ValueKey<String>(_author),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 65,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isComputing ? null : _fetchQuoteLagFree,
                    icon: _isComputing
                        ? const SizedBox.shrink()
                        : const Icon(Icons.auto_awesome, size: 28),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      // FIX 3: Replaced withOpacity with withValues(alpha: ...)
                      shadowColor: Colors.pinkAccent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    label: _isComputing
                        ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    )
                        : const Text(
                      "Surprise ✨",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}