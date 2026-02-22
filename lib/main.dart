import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';

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

  // will hold decompressed quotes in memory
  List? _quotes;

  /// Load and decompress only once
  Future<void> _loadQuotes() async {
    if (_quotes != null) return;

    final data = await rootBundle.load('assets/quotes.gz');
    final bytes = data.buffer.asUint8List();

    final decompressed = GZipDecoder().decodeBytes(bytes);
    final jsonStr = utf8.decode(decompressed);

    final jsonData = json.decode(jsonStr);
    _quotes = jsonData['quotes'];
  }

  /// Pick random short quote
  Future<void> _fetchQuoteLagFree() async {
    setState(() => _isComputing = true);

    try {
      await _loadQuotes();

      final random = Random();

      for (int i = 0; i < 25; i++) {
        final q = _quotes![random.nextInt(_quotes!.length)];

        String quote = q[1].toString();

        if (quote.length <= 160) {
          setState(() {
            _quote = quote;
            _author = q[0].toString();
          });
          return;
        }
      }

      setState(() {
        _quote = "Couldn't find a short quote 🌸";
        _author = "";
      });

    } catch (e) {
      setState(() => _quote = "Error reading quotes file 🥺");
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
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
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