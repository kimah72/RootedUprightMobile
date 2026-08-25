import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WidgetGuide extends StatefulWidget {
  const WidgetGuide({super.key});

  @override
  State<WidgetGuide> createState() => _WidgetGuideState();
}

class _WidgetGuideState extends State<WidgetGuide> {
  // Controls whether the boot sequence is showing
  bool _isLoading = true;
  // Cycles through loading dot states
  String _loadingText = 'LOADING.';

  @override
  void initState() {
    super.initState();
    // Auto-reveal after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });

    // Animate the loading dots
    Stream.periodic(const Duration(milliseconds: 500)).listen((_) {
      if (_isLoading) {
        setState(() {
          if (_loadingText == 'LOADING.') {
            _loadingText = 'LOADING..';
          } else if (_loadingText == 'LOADING..') {
            _loadingText = 'LOADING...';
          } else {
            _loadingText = 'LOADING.';
          }
        });
      }
    });
  }
    
  @override
  Widget build(BuildContext context) {
    // Show boot sequence or haiku based on loading state
    if (_isLoading) {
      return Container(
        color: const Color(0xFF080d00),
        child: Center(
          child: SizedBox(
            width: 200,
            child: Text(
              _loadingText,
              style: GoogleFonts.shareTechMono(
                fontSize: 15,
                color: const Color(0xFFffb000),
                letterSpacing: 4,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      // Void background
      color: const Color(0xFF080d00),
      child: SingleChildScrollView(
        // The widget tree lives here
        child: Column(
          children: [
            // Outermost layer — what a widget is
            // Three haiku children go here
            ExpansionTile(
              // Haiku line 1
              collapsedIconColor: const Color(0xFFffb000),
              iconColor: const Color(0xFFffb000),
              title: Text(
                'WIDGET IS A CLASS',
                style: GoogleFonts.shareTechMono(
                  fontSize: 15,
                  color: const Color(0xFFffb000),
                  letterSpacing: 1,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Everything in Flutter is a widget. '
                    'A widget is a Dart class that describes '
                    'a piece of UI. If you can see it, it is a widget.',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 13,
                      color: const Color(0xBFffb000),
                      letterSpacing: 1,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
              ExpansionTile(
                collapsedIconColor: const Color(0xFFffb000),
                iconColor: const Color(0xFFffb000),
                  title: Text(
                    'PROPERTIES ARE THEN PASSED IN',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 15,
                      color: const Color(0xFFffb000),
                      letterSpacing: 1,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Properties are values passed into a widget when it is created. '
                        'They customize how the widget looks or behaves, '
                        'just like props in React.',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 13,
                          color: const Color(0xBFffb000),
                          letterSpacing: 1,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                collapsedIconColor: const Color(0xFFffb000),
                iconColor: const Color(0xFFffb000),
                  title: Text(
                    'BUILD RETURNS UI',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 15,
                        color: const Color(0xFFffb000),
                        letterSpacing: 1,
                      ),
                    ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'The build method is called by Flutter whenever the widget '
                        'needs to be drawn. It returns the widget tree, '
                        'like returning JSX from a React component.',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 13,
                          color: const Color(0xBFffb000),
                          letterSpacing: 1,
                          height: 1.8,
                        ),
                      ),
                  ),
                ],
              ),
            ExpansionTile(
              // Support the lab easter egg
              collapsedIconColor: const Color(0xFFffb000),
              iconColor: const Color(0xFFffb000),
              title: Text(
                'SUPPORT THE LAB',
                style: GoogleFonts.shareTechMono(
                  fontSize: 15,
                  color: const Color(0xFFffb000),
                  letterSpacing: 1,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This lab runs on curiosity, late nights, and API credits. '
                        'If this little experiment made you smile, '
                        'consider supporting the gardener.',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          color: const Color(0xBFffb000),
                          letterSpacing: 1,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://ko-fi.com/kimah');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          '>> SUPPORT ON KO-FI',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            color: const Color(0xFFffb000),
                            decoration: TextDecoration.underline,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}