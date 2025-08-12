// lib/BIBLE/BibleReaderHome.dart

import 'dart:async';

import 'package:bible/BIBLE/SavedReferencesPage.dart';
import 'package:bible/BIBLE/SettingsPage.dart';
import 'package:bible/BIBLE/VerseSearchDelegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:xml/xml.dart' as xml;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Bible Reader',
    theme: ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    darkTheme: ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: ShowCaseWidget(
      builder: (context) => const BibleReaderHome(),
    ),
  );
}

class ModernWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);

    // Create a more sophisticated wave pattern
    path.quadraticBezierTo(size.width * 0.2, -20, size.width * 0.4, 15);
    path.quadraticBezierTo(size.width * 0.6, 50, size.width * 0.8, 15);
    path.quadraticBezierTo(size.width * 0.9, -10, size.width, 20);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ModernAppColors {
  // Modern darker blue palette - Enhanced for better dark mode visibility
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep blue
  static const Color secondaryBlue = Color(0xFF3B82F6); // Bright blue
  static const Color accentBlue = Color(0xFF60A5FA); // Light blue
  static const Color darkBlue = Color(0xFF1E40AF); // Darker blue
  static const Color lightBlue = Color(0xFFDEF7FF); // Very light blue

  // Enhanced text colors for better visibility
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Brighter white
  static const Color darkTextSecondary = Color(0xFFE2E8F0); // Lighter gray

  // Enhanced background colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B); // Lighter dark card

  // Accent colors with better contrast
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Enhanced shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark =
      Color(0x4A000000); // Darker shadows for better depth

  // Stats colors with better contrast
  static const Color statsBlue = Color(0xFF2563EB);
  static const Color statsGreen = Color(0xFF059669);
  static const Color statsOrange = Color(0xFFD97706);
  static const Color statsPurple = Color(0xFF7C3AED);
  static const Color statsRed = Color(0xFFDC2626);
}

class ModernAppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundLightGradient = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundDarkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Enhanced gradients for dark mode
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Navigation state enum for better state management
enum NavigationState {
  bibleVersions,
  books,
  chapter,
  search,
  stats,
  savedReferences,
}

class BibleReaderHome extends StatefulWidget {
  const BibleReaderHome({super.key});

  @override
  BibleReaderHomeState createState() => BibleReaderHomeState();
}

class BibleReaderHomeState extends State<BibleReaderHome>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keeps state alive for better performance

  // Showcase keys
  final GlobalKey _keyVersion = GlobalKey();
  final GlobalKey _keySearch = GlobalKey();
  final GlobalKey _keyAudio = GlobalKey();
  final GlobalKey _keyNavigation = GlobalKey();
  final GlobalKey _keySwipe = GlobalKey();
  final GlobalKey _keyStats = GlobalKey();
  final GlobalKey _keySettings = GlobalKey();
  final GlobalKey _keyBooks = GlobalKey();
  final GlobalKey _keyChapter = GlobalKey();
  final GlobalKey _keySaveMessage = GlobalKey();
  final GlobalKey _keyDrawer = GlobalKey();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Scroll controller for collapsible header
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;

  // Bible versions - const for better performance
  static const List<BibleVersion> bibleVersions = [
    // Original versions first
    BibleVersion(name: 'Tamil Bible', filePath: 'assets/bible/Tamil Bible.xml'),
    BibleVersion(
        name: 'New King James Version',
        filePath: 'assets/bible/New King James Version (1982).xml'),
    BibleVersion(
        name: 'English Standard Version', filePath: 'assets/bible/esv.xml'),
    BibleVersion(
        name: 'Revised Standard Version', filePath: 'assets/bible/rsv.xml'),
    BibleVersion(
        name: 'New American Standard Bible',
        filePath: 'assets/bible/Bible_English_NASB_Strong.xml'),
    BibleVersion(
        name: 'New International Version (1984) (US)',
        filePath: 'assets/bible/NIV_1984_US.xml'),

    // Combined versions
    BibleVersion(name: 'Combined NKJV', filePath: 'assets/bible/Bible.xml'),
    BibleVersion(name: 'Combined NIV', filePath: 'assets/bible/niv-tamil.xml'),
    BibleVersion(
        name: 'Combined NSAB', filePath: 'assets/bible/nsab-tamil.xml'),
  ];

  // Mapping for bible short names
  static const Map<String, String> bibleShortNames = {
    'Tamil Bible': 'Tamil',
    'New King James Version': 'NKJV',
    'English Standard Version': 'ESV',
    'Revised Standard Version': 'RSV',
    'New American Standard Bible': 'NASB',
    'New International Version (1984) (US)': 'NIV',
    'Combined NKJV': 'NKJV/Tamil',
    'Combined NIV': 'NIV/Tamil',
    'Combined NSAB': 'NSAB/Tamil',
  };

  xml.XmlDocument? bibleXml;
  List<xml.XmlElement> books = [];
  String bibleName = '';
  int currentBibleIndex = 0;
  int currentBookIndex = 0;
  int currentChapterIndex = 0;
  String selectedBookName = '';
  String selectedChapterNumber = '';
  String selectedChapterDisplay = '';
  int totalChapters = 0;
  int totalVerses = 0;
  int totalVersesInBook = 0;
  List<Map<String, String>> savedReferences = [];
  Set<String> bookmarkedReferences = {};

  double fontSize = 16.0;
  bool isDarkTheme = false;

  // Navigation state management
  NavigationState _currentState = NavigationState.bibleVersions;
  List<NavigationState> _navigationHistory = [NavigationState.bibleVersions];
  int _bottomNavIndex = 0;
  String? highlightedReference;

  final FlutterTts flutterTts = FlutterTts();
  bool _isPlaying = false;

  final ItemScrollController _itemScrollController = ItemScrollController();

  // Cache for performance optimization
  final Map<int, Widget> _pageCache = {};

  // UPDATED: Better search state management - This will persist search results
  SearchState? _lastSearchState;
  // ADDED: Track if we came from search to preserve state
  bool _navigatedFromSearch = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initScrollListener();
    loadSettings();
    loadSavedReferences();
    loadXmlFile(currentBibleIndex);
    initTts();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      final bool shouldShowHeader = _scrollController.offset < 100;
      if (shouldShowHeader != _isHeaderVisible) {
        setState(() {
          _isHeaderVisible = shouldShowHeader;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Navigation state management methods
  void _pushState(NavigationState newState) {
    setState(() {
      _navigationHistory.add(newState);
      _currentState = newState;
    });
  }

  void _popState() {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
        _currentState = _navigationHistory.last;
        _updateBottomNavFromState();
      });
    }
  }

  void _updateBottomNavFromState() {
    switch (_currentState) {
      case NavigationState.bibleVersions:
        _bottomNavIndex = 0;
        break;
      case NavigationState.books:
        _bottomNavIndex = 1;
        break;
      case NavigationState.chapter:
        _bottomNavIndex = 3;
        break;
      case NavigationState.stats:
        _bottomNavIndex = 4;
        break;
      default:
        break;
    }
  }

  // UPDATED: Handle back button press for proper navigation with search state preservation
  Future<bool> _handleBackButton() async {
    // If we navigated from search and have search state, go back to search
    if (_navigatedFromSearch && _lastSearchState != null) {
      _navigatedFromSearch = false;
      _startSearchWithState();
      return false; // Don't exit app
    }

    if (_navigationHistory.length > 1) {
      _popState();
      return false; // Don't exit app
    }
    return true; // Allow exit if at root
  }

  Future<void> initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() {});
    });
    flutterTts.setErrorHandler((msg) {});
  }

  Future<void> _speakTamilText(String text) async {
    await flutterTts.stop();
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.speak(text);
    await flutterTts.setLanguage("en-US");
  }

  Future<void> _speakText(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        fontSize = prefs.getDouble('fontSize') ?? 16.0;
        isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      });
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('isDarkTheme', isDarkTheme);
  }

  Future<void> loadXmlFile(int bibleIndex) async {
    try {
      final fileName = bibleVersions[bibleIndex].filePath;
      final xmlData = await rootBundle.loadString(fileName);
      if (mounted) {
        setState(() {
          currentBibleIndex = bibleIndex;
          bibleXml = xml.XmlDocument.parse(xmlData);
          bibleName = bibleVersions[bibleIndex].name;
          books = bibleXml!.findAllElements('BIBLEBOOK').toList();
          if (books.isNotEmpty) {
            loadBook(0);
          } else {
            books = [];
            selectedBookName = '';
            selectedChapterNumber = '';
            selectedChapterDisplay = '';
          }
          // Clear cache when changing bible version
          _pageCache.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar(context, 'Failed to load Bible version',
            isError: true);
      }
    }
  }

  void loadBook(int index) {
    setState(() {
      currentBookIndex = index;
      var book = books[index];

      // FIXED: Properly handle Combined Bible book names
      if (bibleName.contains('Combined')) {
        String enName = book.getAttribute('bname_en') ?? 'Unknown Book';
        String taName = book.getAttribute('bname_ta') ?? 'Unknown Book';
        selectedBookName = '$enName / $taName';
      } else if (bibleName == 'Tamil Bible') {
        selectedBookName = book.getAttribute('bname_ta') ??
            book.getAttribute('bname') ??
            'புத்தகம் தெரியவில்லை';
      } else {
        selectedBookName = book.getAttribute('bname_en') ??
            book.getAttribute('bname') ??
            'Unknown Book';
      }

      var chapters = book.findAllElements('CHAPTER').toList();
      totalChapters = chapters.length;
      if (chapters.isNotEmpty) {
        loadChapter(0);
      } else {
        selectedChapterNumber = '';
        selectedChapterDisplay = '';
      }
    });
  }

  void loadChapter(int index) {
    setState(() {
      currentChapterIndex = index;
      var chapters =
          books[currentBookIndex].findAllElements('CHAPTER').toList();
      var verses = chapters[index].findAllElements('VERS').toList();
      totalVersesInBook =
          books[currentBookIndex].findAllElements('VERS').length;
      totalVerses = verses.length;
      selectedChapterNumber = chapters[index].getAttribute('cnumber') ?? '';
      selectedChapterDisplay = 'Chapter ${currentChapterIndex + 1}';
      if (highlightedReference != null &&
          !highlightedReference!.contains(':$selectedChapterNumber:')) {
        highlightedReference = null;
      }
    });
  }

  Future<void> saveReference(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    if (!bookmarkedReferences.contains(reference)) {
      savedReferences
          .add({'reference': reference, 'date': DateTime.now().toString()});
      bookmarkedReferences.add(reference);
      List<String> savedReferencesString = savedReferences
          .map((e) => "${e['reference']}::${e['date']}")
          .toList();
      await prefs.setStringList('savedReferences', savedReferencesString);
      if (mounted) setState(() {});
    }
  }

  Future<void> removeReference(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    savedReferences.removeWhere((e) => e['reference'] == reference);
    bookmarkedReferences.remove(reference);
    List<String> savedReferencesString =
        savedReferences.map((e) => "${e['reference']}::${e['date']}").toList();
    await prefs.setStringList('savedReferences', savedReferencesString);
    if (mounted) setState(() {});
  }

  Future<void> loadSavedReferences() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedReferencesString =
        prefs.getStringList('savedReferences');
    if (savedReferencesString != null && mounted) {
      savedReferences = savedReferencesString.map((e) {
        List<String> parts = e.split("::");
        return {'reference': parts[0], 'date': parts[1]};
      }).toList();
      bookmarkedReferences =
          savedReferences.map((e) => e['reference']!).toSet();
      setState(() {});
    }
  }

  // UPDATED: Enhanced search function with proper state management
  void _startSearch() async {
    final SearchResult? searchResult = await showSearch<SearchResult?>(
      context: context,
      delegate: VerseSearchDelegate(
        books: books,
        oNSABveReference: saveReference,
        bibleName: bibleName,
        fontSize: fontSize,
        fontColor: isDarkTheme
            ? ModernAppColors.darkTextPrimary
            : ModernAppColors.lightTextPrimary,
        isDarkTheme: isDarkTheme,
        // Pass the current search state
        initialSearchState: _lastSearchState,
      ),
    );

    // Save the search state when delegate closes
    if (searchResult != null) {
      setState(() {
        _lastSearchState = searchResult.searchState;
      });

      // Navigate to verse if one was selected
      if (searchResult.selectedVerse != null) {
        // UPDATED: Mark that we navigated from search
        _navigatedFromSearch = true;
        goToVerse(searchResult.selectedVerse!);
      }
    }
  }

  // ADDED: New method to start search with existing state (for back navigation)
  void _startSearchWithState() async {
    final SearchResult? searchResult = await showSearch<SearchResult?>(
      context: context,
      delegate: VerseSearchDelegate(
        books: books,
        oNSABveReference: saveReference,
        bibleName: bibleName,
        fontSize: fontSize,
        fontColor: isDarkTheme
            ? ModernAppColors.darkTextPrimary
            : ModernAppColors.lightTextPrimary,
        isDarkTheme: isDarkTheme,
        // Pass the preserved search state
        initialSearchState: _lastSearchState,
        // ADDED: Flag to show results immediately
        showResultsImmediately: true,
      ),
    );

    // Update search state
    if (searchResult != null) {
      setState(() {
        _lastSearchState = searchResult.searchState;
      });

      // Navigate to verse if one was selected
      if (searchResult.selectedVerse != null) {
        _navigatedFromSearch = true;
        goToVerse(searchResult.selectedVerse!);
      }
    }
  }

  void _navigateToSavedReferences() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SavedReferencesPage(
        savedReferences: savedReferences,
        getVerseDetails: getVerseDetails,
        onGoToVerse: (reference) {
          Navigator.of(context).pop();
          goToVerse(reference);
        },
        onDeleteReference: (reference) {
          removeReference(reference);
          setState(() {
            savedReferences
                .removeWhere((element) => element['reference'] == reference);
          });
        },
        isDarkTheme: isDarkTheme,
      ),
    ));
  }

  void goToVerse(String reference) {
    List<String> parts = reference.split(' ');
    if (parts.length >= 2) {
      String bookNamePart = parts.sublist(0, parts.length - 1).join(' ');
      String chapterAndVerse = parts.last;
      List<String> chapterVerseParts = chapterAndVerse.split(':');
      if (chapterVerseParts.length >= 2) {
        String chapterNumber = chapterVerseParts[0];
        for (int i = 0; i < books.length; i++) {
          var book = books[i];
          String currentBookName = '';

          // FIXED: Better book name matching for Combined Bibles
          if (bibleName.contains('Combined')) {
            String enBookName = book.getAttribute('bname_en') ?? '';
            String taBookName = book.getAttribute('bname_ta') ?? '';
            currentBookName = '$enBookName / $taBookName';

            // Try matching with either English or Tamil name
            if (currentBookName.contains(bookNamePart) ||
                enBookName == bookNamePart ||
                taBookName == bookNamePart) {
              var chapters = book.findAllElements('CHAPTER').toList();
              for (int j = 0; j < chapters.length; j++) {
                var chapter = chapters[j];
                if (chapter.getAttribute('cnumber') == chapterNumber) {
                  loadBook(i);
                  loadChapter(j);
                  setState(() {
                    _currentState = NavigationState.chapter;
                    _bottomNavIndex = 3;
                    highlightedReference = reference;
                  });
                  _pushState(NavigationState.chapter);
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    _scrollToVerse(reference);
                  });
                  return;
                }
              }
            }
          } else if (bibleName == 'Tamil Bible') {
            String taBookName = book.getAttribute('bname_ta') ??
                book.getAttribute('bname') ??
                '';
            currentBookName = taBookName;
            if (currentBookName == bookNamePart) {
              var chapters = book.findAllElements('CHAPTER').toList();
              for (int j = 0; j < chapters.length; j++) {
                var chapter = chapters[j];
                if (chapter.getAttribute('cnumber') == chapterNumber) {
                  loadBook(i);
                  loadChapter(j);
                  setState(() {
                    _currentState = NavigationState.chapter;
                    _bottomNavIndex = 3;
                    highlightedReference = reference;
                  });
                  _pushState(NavigationState.chapter);
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    _scrollToVerse(reference);
                  });
                  return;
                }
              }
            }
          } else {
            String enBookName = book.getAttribute('bname_en') ??
                book.getAttribute('bname') ??
                '';
            currentBookName = enBookName;
            if (currentBookName == bookNamePart) {
              var chapters = book.findAllElements('CHAPTER').toList();
              for (int j = 0; j < chapters.length; j++) {
                var chapter = chapters[j];
                if (chapter.getAttribute('cnumber') == chapterNumber) {
                  loadBook(i);
                  loadChapter(j);
                  setState(() {
                    _currentState = NavigationState.chapter;
                    _bottomNavIndex = 3;
                    highlightedReference = reference;
                  });
                  _pushState(NavigationState.chapter);
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    _scrollToVerse(reference);
                  });
                  return;
                }
              }
            }
          }
        }
      }
    }
  }

  void _scrollToVerse(String reference) {
    List<String> parts = reference.split(' ');
    if (parts.length >= 2) {
      String chapterAndVerse = parts.last;
      List<String> chapterVerseParts = chapterAndVerse.split(':');
      if (chapterVerseParts.length >= 2) {
        int verseIndex = int.tryParse(chapterVerseParts[1]) ?? 0;
        if (verseIndex > 0) {
          _itemScrollController.scrollTo(
            index: verseIndex - 1,
            duration: const Duration(milliseconds: 500),
            alignment: 0.1,
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  String getVerseDetails(String reference) {
    List<String> parts = reference.split(' ');
    if (parts.length >= 2) {
      String bookNamePart = parts.sublist(0, parts.length - 1).join(' ');
      String chapterAndVerse = parts.last;
      List<String> chapterVerseParts = chapterAndVerse.split(':');
      if (chapterVerseParts.length >= 2) {
        String chapterNumber = chapterVerseParts[0];
        String verseNumber = chapterVerseParts[1];
        for (var book in books) {
          String currentBookName = '';

          // FIXED: Handle Combined Bible verse details
          if (bibleName.contains('Combined')) {
            String enBookName = book.getAttribute('bname_en') ?? '';
            String taBookName = book.getAttribute('bname_ta') ?? '';
            currentBookName = '$enBookName / $taBookName';
            if (currentBookName.contains(bookNamePart)) {
              var chapters = book.findAllElements('CHAPTER').toList();
              for (var chapter in chapters) {
                if (chapter.getAttribute('cnumber') == chapterNumber) {
                  var verse = chapter.findAllElements('VERS').firstWhere(
                      (v) => v.getAttribute('vnumber') == verseNumber,
                      orElse: () => xml.XmlElement(xml.XmlName('VERS')));
                  if (verse.name.local != 'VERS') continue;

                  String enText = verse.findElements('EN').isNotEmpty
                      ? verse.findElements('EN').first.innerText.trim()
                      : '';
                  String taText = verse.findElements('TA').isNotEmpty
                      ? verse.findElements('TA').first.innerText.trim()
                      : '';

                  if (enText.isNotEmpty && taText.isNotEmpty) {
                    return 'English: $enText\nTamil: $taText';
                  } else if (enText.isNotEmpty) {
                    return 'English: $enText';
                  } else if (taText.isNotEmpty) {
                    return 'Tamil: $taText';
                  } else {
                    return verse.innerText.trim();
                  }
                }
              }
            }
          } else {
            String bookName = book.getAttribute('bname_en') ??
                book.getAttribute('bname_ta') ??
                book.getAttribute('bname') ??
                '';
            currentBookName = bookName;
            if (currentBookName == bookNamePart) {
              var chapters = book.findAllElements('CHAPTER').toList();
              for (var chapter in chapters) {
                if (chapter.getAttribute('cnumber') == chapterNumber) {
                  var verse = chapter.findAllElements('VERS').firstWhere(
                      (v) => v.getAttribute('vnumber') == verseNumber,
                      orElse: () => xml.XmlElement(xml.XmlName('VERS')));
                  if (verse.name.local != 'VERS') continue;

                  // Try to get text from EN tag first, then fallback to inner text
                  String verseText = verse.findElements('EN').isNotEmpty
                      ? verse.findElements('EN').first.innerText.trim()
                      : verse.innerText.trim();
                  return verseText;
                }
              }
            }
          }
        }
      }
    }
    return 'No details found';
  }

  String _getChapterText() {
    var chapter = books[currentBookIndex]
        .findAllElements('CHAPTER')
        .elementAt(currentChapterIndex);
    var verses = chapter.findAllElements('VERS').toList();
    String chapterText = "";
    for (var verse in verses) {
      String verseText = "";

      // FIXED: Handle Combined Bible text extraction
      if (bibleName.contains('Combined')) {
        if (verse.findElements('EN').isNotEmpty) {
          verseText = verse.findElements('EN').first.innerText.trim();
        }
      } else {
        if (verse.findElements('EN').isNotEmpty) {
          verseText = verse.findElements('EN').first.innerText.trim();
        } else {
          verseText = verse.innerText.trim();
        }
      }
      chapterText += "$verseText\n";
    }
    return chapterText;
  }

  Future<void> _speakFullChapter() async {
    String chapterText = _getChapterText();
    List<String> verses =
        chapterText.split("\n").where((s) => s.trim().isNotEmpty).toList();
    for (String verse in verses) {
      if (!_isPlaying) break;
      await flutterTts.speak(verse);
      await flutterTts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _togglePlayChapter() async {
    if (_isPlaying) {
      await flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _speakFullChapter();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _showModernSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? ModernAppColors.error : ModernAppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin

    final bgGradient = isDarkTheme
        ? ModernAppGradients.backgroundDarkGradient
        : ModernAppGradients.backgroundLightGradient;

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        backgroundColor: isDarkTheme
            ? ModernAppColors.darkBackground
            : ModernAppColors.lightBackground,
        drawer: _buildModernDrawer(),
        appBar: _buildModernAppBar(),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(gradient: bgGradient),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildCurrentPage(),
                  ),
                ),
              ),
              _buildModernBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentState) {
      case NavigationState.bibleVersions:
        return bibleVersionsTab();
      case NavigationState.books:
        return booksTab();
      case NavigationState.chapter:
        return chapterDetailsTab();
      case NavigationState.stats:
        return statsTab();
      default:
        return bibleVersionsTab();
    }
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Text(
        'Bible Reader',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(
        color: isDarkTheme
            ? ModernAppColors.darkTextPrimary
            : ModernAppColors.lightTextPrimary,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDarkTheme
              ? ModernAppGradients.backgroundDarkGradient
              : ModernAppGradients.backgroundLightGradient,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: isDarkTheme
                ? ModernAppColors.cardDark
                : ModernAppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDarkTheme
                    ? ModernAppColors.shadowDark
                    : ModernAppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: ModernAppColors.secondaryBlue,
            ),
            onPressed: () {
              ShowCaseWidget.of(context).startShowCase([
                _keyVersion,
                _keyBooks,
                _keyChapter,
                _keySearch,
                _keySaveMessage,
                _keyDrawer,
                _keyAudio,
                _keyNavigation,
                _keyStats,
                _keySettings,
              ]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: isDarkTheme
          ? ModernAppColors.darkBackground
          : ModernAppColors.lightBackground,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDarkTheme
              ? ModernAppGradients.backgroundDarkGradient
              : ModernAppGradients.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Showcase(
                key: _keyDrawer,
                description:
                    "Swipe from the left edge (or tap here) to open the menu and see your saved bookmarks and settings.",
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: ModernAppGradients.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.menu_book,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bible Reader',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Explore the Word',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildDrawerItem(
                      key: _keySettings,
                      icon: Icons.settings,
                      title: 'Settings',
                      description:
                          "Tap here to open settings for dark mode and font size adjustments.",
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            fontSize: fontSize,
                            isDarkTheme: isDarkTheme,
                            onFontSizeChanged: (newSize) {
                              setState(() {
                                fontSize = newSize;
                                _pageCache
                                    .clear(); // Clear cache when settings change
                              });
                              saveSettings();
                            },
                            onThemeChanged: (newTheme) {
                              setState(() {
                                isDarkTheme = newTheme;
                                _pageCache
                                    .clear(); // Clear cache when theme changes
                              });
                              saveSettings();
                            },
                          ),
                        ));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.library_books,
                      title: 'Versions',
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _currentState = NavigationState.bibleVersions;
                          _bottomNavIndex = 0;
                        });
                        _pushState(NavigationState.bibleVersions);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.bookmark,
                      title: 'Saved References',
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToSavedReferences();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.assessment,
                      title: 'Statistics',
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _currentState = NavigationState.stats;
                          _bottomNavIndex = 4;
                        });
                        _pushState(NavigationState.stats);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    GlobalKey? key,
    required IconData icon,
    required String title,
    String? description,
    required VoidCallback onTap,
  }) {
    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ModernAppGradients.secondaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkTheme
                ? ModernAppColors.darkTextPrimary
                : ModernAppColors.lightTextPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (key != null && description != null) {
      return Showcase(
        key: key,
        description: description,
        child: content,
      );
    }
    return content;
  }

  Widget _buildModernBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: isDarkTheme
                  ? ModernAppGradients.darkCardGradient
                  : ModernAppGradients.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: ModernAppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernNavIcon(Icons.menu_book, 0, "Versions",
                    NavigationState.bibleVersions),
                _buildModernNavIcon(
                    Icons.book, 1, "Books", NavigationState.books),
                _buildModernNavIcon(
                    Icons.search, 2, "Search", NavigationState.search),
                _buildModernNavIcon(Icons.chrome_reader_mode, 3, "Chapter",
                    NavigationState.chapter),
                _buildModernNavIcon(
                    Icons.assessment, 4, "Stats", NavigationState.stats),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavIcon(
      IconData iconData, int index, String label, NavigationState state) {
    bool isSelected = _bottomNavIndex == index;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isSelected ? 16 : 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              iconData,
              color: isSelected ? Colors.white : Colors.white70,
              size: isSelected ? 26 : 24,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: isSelected ? 13 : 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ],
      ),
    );

    Widget inkWellWidget = InkWell(
      onTap: () {
        if (index == 2) {
          _startSearch();
        } else {
          setState(() {
            _bottomNavIndex = index;
            _currentState = state;
          });
          _pushState(state);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: content,
    );

    // Conditionally wrap with Showcase only when we have a key
    if (index == 2) {
      return Showcase(
        key: _keySearch,
        description: "Tap here to open the search page.",
        child: inkWellWidget,
      );
    } else if (index == 4) {
      return Showcase(
        key: _keyStats,
        description: "Tap here to view statistics.",
        child: inkWellWidget,
      );
    } else {
      return inkWellWidget;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Bible versions page – header scrolls away, cards stay the same
  // FIXED: Added proper bottom padding to prevent hiding under navigation
  // ─────────────────────────────────────────────────────────────────────────────
  Widget bibleVersionsTab() {
    return Showcase(
      key: _keyVersion,
      description: "Select a Bible version from here.",
      child: SafeArea(
        child: NestedScrollView(
          // ── 1. SLIVER HEADER (blue container) ────────────────────────────────
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ModernAppColors.primaryBlue,
                      ModernAppColors.secondaryBlue,
                      ModernAppColors.accentBlue,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.menu_book,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Choose Your Bible',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Select from ${bibleVersions.length} available versions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Current selection chip
                    if (bibleName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Currently: ${bibleShortNames[bibleName] ?? bibleName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // ── 2. BODY (scrollable list of cards) ───────────────────────────────
          // FIXED: Added proper bottom padding for navigation bar
          body: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                20, 0, 20, 120), // FIXED: Added bottom padding
            itemCount: bibleVersions.length,
            itemBuilder: (context, index) {
              final version = bibleVersions[index];
              final isSelected = currentBibleIndex == index;
              final shortName = bibleShortNames[version.name] ?? '';

              return _buildVersionCard(
                version: version,
                isSelected: isSelected,
                shortName: shortName,
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await loadXmlFile(index);
                  setState(() {
                    _bottomNavIndex = 1;
                    _currentState = NavigationState.books;
                  });
                  _pushState(NavigationState.books);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helper that builds one animated card. This is identical to the card you
  // already wrote—only wrapped in its own method for clarity.
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildVersionCard({
    required BibleVersion version,
    required bool isSelected,
    required String shortName,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(bottom: 20),
      transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ModernAppColors.primaryBlue,
                    ModernAppColors.secondaryBlue,
                  ],
                )
              : null,
          color: !isSelected
              ? (isDarkTheme
                  ? ModernAppColors.cardDark
                  : ModernAppColors.cardLight)
              : null,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
              : Border.all(
                  color: isDarkTheme
                      ? ModernAppColors.darkTextSecondary.withOpacity(0.1)
                      : ModernAppColors.lightTextSecondary.withOpacity(0.1),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ModernAppColors.primaryBlue.withOpacity(0.4)
                  : (isDarkTheme
                      ? ModernAppColors.shadowDark
                      : ModernAppColors.shadowLight),
              blurRadius: isSelected ? 24 : 12,
              offset: Offset(0, isSelected ? 12 : 4),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // ── Icon block ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                ModernAppColors.accentBlue.withOpacity(0.1),
                                ModernAppColors.secondaryBlue.withOpacity(0.1),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : ModernAppColors.accentBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _getVersionIcon(version.name),
                      size: 32,
                      color: isSelected
                          ? Colors.white
                          : ModernAppColors.secondaryBlue,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // ── Text block ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          version.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDarkTheme
                                    ? ModernAppColors.darkTextPrimary
                                    : ModernAppColors.lightTextPrimary),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Badges
                        Row(
                          children: [
                            if (shortName.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : ModernAppColors.accentBlue
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : ModernAppColors.accentBlue
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  shortName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : ModernAppColors.secondaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (version.name.contains('Combined')) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      ModernAppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Bilingual',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: ModernAppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                            if (version.name.contains('Tamil')) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      ModernAppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tamil',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: ModernAppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          _getVersionDescription(version.name),
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : (isDarkTheme
                                    ? ModernAppColors.darkTextSecondary
                                    : ModernAppColors.lightTextSecondary),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ── Trailing icon ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(Icons.check_circle,
                                color: Colors.white, size: 24),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  ModernAppColors.accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    ModernAppColors.accentBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Icon(Icons.arrow_forward_ios,
                                color: ModernAppColors.secondaryBlue, size: 20),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get appropriate icon for each version
  IconData _getVersionIcon(String versionName) {
    if (versionName.contains('Tamil')) {
      return Icons.translate;
    } else if (versionName.contains('Combined')) {
      return Icons.language;
    } else if (versionName.contains('King James')) {
      return Icons.auto_stories;
    } else if (versionName.contains('Standard')) {
      return Icons.book;
    } else if (versionName.contains('International')) {
      return Icons.public;
    }
    return Icons.menu_book;
  }

  // Helper method to get description for each version
  String _getVersionDescription(String versionName) {
    switch (versionName) {
      case 'Tamil Bible':
        return 'Tamil language Bible for native Tamil speakers';
      case 'New King James Version':
        return 'Modern English with traditional style and accuracy';
      case 'Combined NKJV':
      case 'Combined NIV':
      case 'Combined NSAB':
        return 'Bilingual Bible with both English and Tamil text';
      case 'English Standard Version':
        return 'Literal translation emphasizing word-for-word accuracy';
      case 'Revised Standard Version':
        return 'Classic English translation widely used in churches';
      case 'New American Standard Bible':
        return 'Highly literal translation preferred for study';
      case 'New International Version (1984) (US)':
        return 'Popular modern English translation for daily reading';
      default:
        return 'Biblical text in your preferred translation';
    }
  }

  // FIXED: Added proper bottom padding to prevent hiding under navigation
  Widget booksTab() {
    return Showcase(
      key: _keyBooks,
      description: "This is the Books tab. Select a book to view its chapters.",
      child: books.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextSecondary
                        : ModernAppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Bible Version Loaded',
                    style: TextStyle(
                      color: isDarkTheme
                          ? ModernAppColors.darkTextPrimary
                          : ModernAppColors.lightTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select a version first',
                    style: TextStyle(
                      color: isDarkTheme
                          ? ModernAppColors.darkTextSecondary
                          : ModernAppColors.lightTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Books of the Bible',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDarkTheme
                                ? ModernAppColors.darkTextPrimary
                                : ModernAppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${books.length} books available',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkTheme
                                ? ModernAppColors.darkTextSecondary
                                : ModernAppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      // FIXED: Added proper bottom padding for navigation bar
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        var book = books[index];
                        var chapters = book.findAllElements('CHAPTER').length;
                        var verses = book.findAllElements('VERS').length;
                        bool isSelected = currentBookIndex == index;

                        String bookName;
                        // FIXED: Better handling of Combined Bible book names
                        if (bibleName.contains('Combined')) {
                          String enName =
                              book.getAttribute('bname_en') ?? 'Unknown Book';
                          String taName =
                              book.getAttribute('bname_ta') ?? 'Unknown Book';
                          bookName = '$enName / $taName';
                        } else if (bibleName == 'Tamil Bible') {
                          bookName = book.getAttribute('bname_ta') ??
                              book.getAttribute('bname') ??
                              'Unknown Book';
                        } else {
                          bookName = book.getAttribute('bname_en') ??
                              book.getAttribute('bname') ??
                              'Unknown Book';
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? ModernAppColors.cardDark
                                : ModernAppColors.cardLight,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: ModernAppColors.secondaryBlue,
                                    width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? ModernAppColors.secondaryBlue
                                        .withOpacity(0.2)
                                    : (isDarkTheme
                                        ? ModernAppColors.shadowDark
                                        : ModernAppColors.shadowLight),
                                blurRadius: isSelected ? 16 : 8,
                                offset: Offset(0, isSelected ? 6 : 2),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              key: Key(bookName),
                              initiallyExpanded: isSelected,
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? ModernAppGradients.primaryGradient
                                      : ModernAppGradients.secondaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                bookName,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDarkTheme
                                      ? ModernAppColors.darkTextPrimary
                                      : ModernAppColors.lightTextPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    _buildBookStat('Chapters',
                                        chapters.toString(), Icons.menu_book),
                                    const SizedBox(width: 16),
                                    _buildBookStat('Verses', verses.toString(),
                                        Icons.format_quote),
                                  ],
                                ),
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chapters,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                    itemBuilder: (context, chapterIndex) {
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () {
                                            loadBook(index);
                                            loadChapter(chapterIndex);
                                            setState(() {
                                              _bottomNavIndex = 3;
                                              _currentState =
                                                  NavigationState.chapter;
                                            });
                                            _pushState(NavigationState.chapter);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: ModernAppGradients
                                                  .cardGradient,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: ModernAppColors
                                                      .primaryBlue
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${chapterIndex + 1}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkTheme
              ? ModernAppColors.darkTextSecondary
              : ModernAppColors.lightTextSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: isDarkTheme
                ? ModernAppColors.darkTextSecondary
                : ModernAppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget chapterDetailsTab() {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chrome_reader_mode_outlined,
              size: 64,
              color: isDarkTheme
                  ? ModernAppColors.darkTextSecondary
                  : ModernAppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Bible Version Loaded',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextPrimary
                    : ModernAppColors.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a version and book first',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    String versionLabel =
        bibleName.contains('Combined') ? 'NKJV/Tamil' : bibleName;

    return Showcase(
      key: _keyChapter,
      description:
          "This is the Chapter view. Read the verses, swipe left/right to navigate, and long press a verse to save a message.",
      child: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            Showcase(
              key: _keySwipe,
              description: "Swipe left/right to change chapters.",
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx < -300) {
                    if (_canGoToNextChapter()) _goToNextChapter();
                  } else if (details.velocity.pixelsPerSecond.dx > 300) {
                    if (_canGoToPreviousChapter()) _goToPreviousChapter();
                  }
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Scrollable Header with centered book name and chapter
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkTheme
                              ? ModernAppColors.cardDark
                              : ModernAppColors.cardLight,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkTheme
                                  ? ModernAppColors.shadowDark
                                  : ModernAppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Centered Book name
                            Text(
                              selectedBookName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDarkTheme
                                    ? ModernAppColors.darkTextPrimary
                                    : ModernAppColors.lightTextPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Centered Chapter name
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient:
                                      ModernAppGradients.secondaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  selectedChapterDisplay,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Navigation buttons
                            _buildModernNavigationButtons(),
                          ],
                        ),
                      ),
                    ),

                    // Verses list
                    SliverPadding(
                      padding: const EdgeInsets.only(
                          bottom: 120), // Space for bottom nav
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildModernVerseCard(index, versionLabel);
                          },
                          childCount: books[currentBookIndex]
                              .findAllElements('CHAPTER')
                              .elementAt(currentChapterIndex)
                              .findAllElements('VERS')
                              .length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scroll to top button
            if (!_isHeaderVisible)
              Positioned(
                right: 16,
                bottom: 140, // Above the bottom navigation
                child: AnimatedOpacity(
                  opacity: _isHeaderVisible ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ModernAppGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ModernAppColors.primaryBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernVerseCard(int index, String versionLabel) {
    var chapter = books[currentBookIndex]
        .findAllElements('CHAPTER')
        .elementAt(currentChapterIndex);
    var verse = chapter.findAllElements('VERS').elementAt(index);
    String verseNumber = verse.getAttribute('vnumber') ?? '';
    String verseTextEnglish = "";
    String verseTextTamil = "";

    // FIXED: Properly handle Combined Bible text extraction
    if (bibleName.contains('Combined')) {
      if (verse.findElements('EN').isNotEmpty) {
        verseTextEnglish = verse.findElements('EN').first.innerText.trim();
      }
      if (verse.findElements('TA').isNotEmpty) {
        verseTextTamil = verse.findElements('TA').first.innerText.trim();
      }
    } else {
      if (verse.findElements('EN').isNotEmpty) {
        verseTextEnglish = verse.findElements('EN').first.innerText.trim();
      } else {
        verseTextEnglish = verse.innerText.trim();
      }
    }

    String reference = '$selectedBookName $selectedChapterNumber:$verseNumber';
    bool isBookmarked = bookmarkedReferences.contains(reference);
    bool isHighlighted = highlightedReference == reference;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: ModernAppColors.secondaryBlue, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? ModernAppColors.secondaryBlue.withOpacity(0.2)
                : (isDarkTheme
                    ? ModernAppColors.shadowDark
                    : ModernAppColors.shadowLight),
            blurRadius: isHighlighted ? 16 : 8,
            offset: Offset(0, isHighlighted ? 6 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              highlightedReference =
                  highlightedReference == reference ? null : reference;
              if (highlightedReference != null) _scrollToVerse(reference);
            });
          },
          onLongPress: () {
            // Added try-catch for error handling
            try {
              _showModernBottomSheet(
                reference,
                verseTextEnglish,
                verseTextTamil,
                isBookmarked,
              );
            } catch (e) {
              print('Error showing bottom sheet: $e');
              _showModernSnackBar(context, 'Error opening verse actions',
                  isError: true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Updated verse header with uniform styling
                Row(
                  children: [
                    // Verse number with light blue background and blue text (matching others)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ModernAppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        verseNumber,
                        style: const TextStyle(
                          color: ModernAppColors.secondaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Spacer to push items to the right
                    const Spacer(),

                    // Bookmark icon if saved
                    if (isBookmarked) ...[
                      const Icon(
                        Icons.bookmark,
                        color: ModernAppColors.secondaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Version label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ModernAppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bibleShortNames[bibleName] ?? bibleName,
                        style: const TextStyle(
                          color: ModernAppColors.secondaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Speaker icon
                    Container(
                      decoration: BoxDecoration(
                        color: ModernAppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.volume_up,
                          color: ModernAppColors.accentBlue,
                          size: 18,
                        ),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          // Determine which text to speak based on Bible type
                          if (bibleName.contains('Combined')) {
                            if (verseTextEnglish.isNotEmpty) {
                              _speakText(verseTextEnglish);
                            }
                          } else if (bibleName == 'Tamil Bible') {
                            _speakTamilText(verseTextEnglish);
                          } else {
                            _speakText(verseTextEnglish);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Verse content without justification
                if (bibleName.contains('Combined')) ...[
                  if (verseTextEnglish.isNotEmpty)
                    _buildJustifiedVerseTextSimple(
                        verseTextEnglish, isHighlighted),
                  if (verseTextTamil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildJustifiedVerseTextSimple(
                        verseTextTamil, isHighlighted),
                  ],
                ] else ...[
                  _buildJustifiedVerseTextSimple(
                      verseTextEnglish, isHighlighted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJustifiedVerseTextSimple(String text, bool isHighlighted) {
    return Text(
      text,
      style: TextStyle(
        color: isDarkTheme
            ? ModernAppColors.darkTextPrimary
            : ModernAppColors.lightTextPrimary,
        fontSize: isHighlighted ? fontSize + 4 : fontSize,
        height: 1.6,
        fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  Widget _buildVerseText(String version, String text, bool isHighlighted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ModernAppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                version,
                style: const TextStyle(
                  color: ModernAppColors.secondaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.volume_up,
                color: ModernAppColors.accentBlue,
                size: 20,
              ),
              onPressed: () {
                if (version == 'Tamil') {
                  _speakTamilText(text);
                } else {
                  _speakText(text);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: isDarkTheme
                ? ModernAppColors.darkTextPrimary
                : ModernAppColors.lightTextPrimary,
            fontSize: isHighlighted ? fontSize + 4 : fontSize,
            height: 1.6,
            fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showModernBottomSheet(String reference, String verseTextEnglish,
      String verseTextTamil, bool isBookmarked) {
    // Ensure we have valid data
    if (reference.isEmpty) {
      _showModernSnackBar(context, 'Invalid verse reference', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        // Build copy text properly with null checks
        String copyText = reference;
        if (verseTextEnglish.isNotEmpty) {
          copyText += '\n\n$verseTextEnglish';
        }
        if (verseTextTamil.isNotEmpty) {
          copyText += '\n\nTamil: $verseTextTamil';
        }

        return Container(
          decoration: BoxDecoration(
            color: isDarkTheme
                ? ModernAppColors.cardDark
                : ModernAppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: ModernAppColors.shadowDark,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkTheme
                          ? ModernAppColors.darkTextSecondary
                          : ModernAppColors.lightTextSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verse Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme
                          ? ModernAppColors.darkTextPrimary
                          : ModernAppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () {
                          try {
                            Clipboard.setData(ClipboardData(text: copyText));
                            Navigator.pop(modalContext);
                            _showModernSnackBar(context, 'Copied to clipboard');
                          } catch (e) {
                            Navigator.pop(modalContext);
                            _showModernSnackBar(context, 'Failed to copy',
                                isError: true);
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        label: isBookmarked ? 'Remove' : 'Save',
                        onTap: () {
                          try {
                            if (isBookmarked) {
                              removeReference(reference);
                              _showModernSnackBar(
                                  context, 'Removed from bookmarks');
                            } else {
                              saveReference(reference);
                              _showModernSnackBar(
                                  context, 'Saved to bookmarks');
                            }
                            Navigator.pop(modalContext);
                          } catch (e) {
                            Navigator.pop(modalContext);
                            _showModernSnackBar(context, 'Action failed',
                                isError: true);
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          try {
                            // Build share text properly
                            String versionName =
                                bibleShortNames[bibleName] ?? bibleName;
                            String shareText = '$versionName - $reference';

                            if (verseTextEnglish.isNotEmpty) {
                              shareText += '\n\n$verseTextEnglish';
                            }
                            if (verseTextTamil.isNotEmpty) {
                              shareText += '\n\nTamil: $verseTextTamil';
                            }

                            Share.share(shareText);
                            Navigator.pop(modalContext);
                          } catch (e) {
                            Navigator.pop(modalContext);
                            _showModernSnackBar(context, 'Failed to share',
                                isError: true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Add some bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: ModernAppColors.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme
                      ? ModernAppColors.darkTextPrimary
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavigationButtons() {
    return Showcase(
      key: _keyNavigation,
      description:
          "Use these buttons to navigate chapters and books, or tap the audio button to listen.",
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkTheme
              ? ModernAppColors.cardDark
              : ModernAppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkTheme
                  ? ModernAppColors.shadowDark
                  : ModernAppColors.shadowLight,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              icon: Icons.skip_previous,
              onPressed: _canGoToPreviousBook() ? _goToPreviousBook : null,
              tooltip: 'Previous Book',
            ),
            _buildNavButton(
              icon: Icons.chevron_left,
              onPressed:
                  _canGoToPreviousChapter() ? _goToPreviousChapter : null,
              tooltip: 'Previous Chapter',
            ),
            Showcase(
              key: _keyAudio,
              description:
                  "Tap here to play or pause the audio reading of this chapter.",
              child: _buildNavButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _togglePlayChapter,
                tooltip: _isPlaying ? 'Pause' : 'Play',
                isAudio: true,
              ),
            ),
            _buildNavButton(
              icon: Icons.chevron_right,
              onPressed: _canGoToNextChapter() ? _goToNextChapter : null,
              tooltip: 'Next Chapter',
            ),
            _buildNavButton(
              icon: Icons.skip_next,
              onPressed: _canGoToNextBook() ? _goToNextBook : null,
              tooltip: 'Next Book',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isAudio = false,
  }) {
    bool isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? (isAudio
                      ? ModernAppGradients.primaryGradient
                      : ModernAppGradients.secondaryGradient)
                  : null,
              color: !isEnabled
                  ? (isDarkTheme
                          ? ModernAppColors.darkTextSecondary
                          : ModernAppColors.lightTextSecondary)
                      .withOpacity(0.2)
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: (isAudio
                                ? ModernAppColors.primaryBlue
                                : ModernAppColors.accentBlue)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isEnabled
                  ? Colors.white
                  : (isDarkTheme
                      ? ModernAppColors.darkTextSecondary
                      : ModernAppColors.lightTextSecondary),
              size: isAudio ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }

  // Fixed navigation methods
  bool _canGoToPreviousBook() => currentBookIndex > 0;
  bool _canGoToNextBook() => currentBookIndex < books.length - 1;

  void _goToPreviousBook() {
    if (_canGoToPreviousBook()) {
      loadBook(currentBookIndex - 1);
      loadChapter(0);
      setState(() {
        highlightedReference = null;
      });
    }
  }

  void _goToNextBook() {
    if (_canGoToNextBook()) {
      loadBook(currentBookIndex + 1);
      loadChapter(0);
      setState(() {
        highlightedReference = null;
      });
    }
  }

  bool _canGoToPreviousChapter() {
    if (currentChapterIndex > 0) return true;
    return _canGoToPreviousBook();
  }

  bool _canGoToNextChapter() {
    if (currentChapterIndex < totalChapters - 1) return true;
    return _canGoToNextBook();
  }

  void _goToPreviousChapter() {
    if (currentChapterIndex > 0) {
      loadChapter(currentChapterIndex - 1);
    } else if (_canGoToPreviousBook()) {
      loadBook(currentBookIndex - 1);
      loadChapter(totalChapters - 1); // Go to last chapter of previous book
    }
    setState(() {
      highlightedReference = null;
    });
  }

  void _goToNextChapter() {
    if (currentChapterIndex < totalChapters - 1) {
      loadChapter(currentChapterIndex + 1);
    } else if (_canGoToNextBook()) {
      loadBook(currentBookIndex + 1);
      loadChapter(0); // Go to first chapter of next book
    }
    setState(() {
      highlightedReference = null;
    });
  }

  // COMPLETELY REDESIGNED STATS TAB - More informative and no overflow
  // FIXED: Added proper bottom padding to prevent hiding under navigation
  Widget statsTab() {
    if (books.isEmpty) {
      return _buildEmptyStatsState();
    }

    // Calculate detailed statistics
    final statsData = _calculateDetailedStats();

    return SafeArea(
      child: Column(
        children: [
          // Enhanced Header with Bible Info
          _buildStatsHeader(),

          // Main Statistics Grid
          Expanded(
            child: SingleChildScrollView(
              // FIXED: Added proper bottom padding for navigation bar
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              child: Column(
                children: [
                  // Primary Stats Cards
                  _buildPrimaryStatsGrid(statsData),
                  const SizedBox(height: 20),

                  // Detailed Analysis Cards
                  _buildDetailedAnalysisCards(statsData),
                  const SizedBox(height: 20),

                  // Reading Progress Section
                  _buildReadingProgressSection(statsData),
                  const SizedBox(height: 20),

                  // Testament Breakdown
                  _buildTestamentBreakdown(statsData),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatsState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkTheme
              ? ModernAppColors.cardDark
              : ModernAppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDarkTheme
                  ? ModernAppColors.shadowDark
                  : ModernAppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ModernAppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assessment_outlined,
                size: 64,
                color: ModernAppColors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Statistics Available',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextPrimary
                    : ModernAppColors.lightTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please select a Bible version to view detailed statistics and insights',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ModernAppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ModernAppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bible Statistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      bibleShortNames[bibleName] ?? bibleName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('📚', '${books.length}', 'Books'),
                _buildQuickStat('📄', '${_getTotalChapters()}', 'Chapters'),
                _buildQuickStat('✍️', '${_getTotalVerses()}', 'Verses'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryStatsGrid(Map<String, dynamic> statsData) {
    final primaryStats = [
      {
        'icon': Icons.library_books,
        'value': _formatNumber(statsData['totalBooks']),
        'label': 'Total Books',
        'color': ModernAppColors.statsBlue,
        'subtitle':
            '${statsData['oldTestament']} OT + ${statsData['newTestament']} NT'
      },
      {
        'icon': Icons.article,
        'value': _formatNumber(statsData['totalChapters']),
        'label': 'Chapters',
        'color': ModernAppColors.statsGreen,
        'subtitle':
            'Avg ${(statsData['totalChapters'] / statsData['totalBooks']).toStringAsFixed(1)} per book'
      },
      {
        'icon': Icons.format_quote,
        'value': _formatNumber(statsData['totalVerses']),
        'label': 'Verses',
        'color': ModernAppColors.statsOrange,
        'subtitle':
            'Avg ${(statsData['totalVerses'] / statsData['totalChapters']).toStringAsFixed(1)} per chapter'
      },
      {
        'icon': Icons.text_fields,
        'value': _formatNumber(statsData['totalWords']),
        'label': 'Words',
        'color': ModernAppColors.statsPurple,
        'subtitle':
            'Avg ${(statsData['totalWords'] / statsData['totalVerses']).toStringAsFixed(1)} per verse'
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjusted for better content fit
      ),
      itemCount: primaryStats.length,
      itemBuilder: (context, index) {
        final stat = primaryStats[index];
        return _buildEnhancedStatCard(
          stat['icon'] as IconData,
          stat['value'] as String,
          stat['label'] as String,
          stat['color'] as Color,
          subtitle: stat['subtitle'] as String,
        );
      },
    );
  }

  Widget _buildEnhancedStatCard(
    IconData icon,
    String value,
    String label,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDarkTheme
                    ? ModernAppColors.darkTextPrimary
                    : ModernAppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysisCards(Map<String, dynamic> statsData) {
    return Column(
      children: [
        // Reading Time Estimate Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ModernAppColors.statsGreen.withOpacity(0.1),
                ModernAppColors.statsBlue.withOpacity(0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ModernAppColors.statsGreen.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ModernAppColors.statsGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: ModernAppColors.statsGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Reading Time Estimates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDarkTheme
                          ? ModernAppColors.darkTextPrimary
                          : ModernAppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeEstimate(
                      '📖 Complete Bible',
                      '${(statsData['totalWords'] / 200 / 60).toStringAsFixed(0)} hours',
                      'At 200 words/min',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeEstimate(
                      '📝 Average Chapter',
                      '${(statsData['avgWordsPerChapter'] / 200).toStringAsFixed(1)} min',
                      'Typical reading time',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Language Analysis Card (if Combined version)
        if (bibleName.contains('Combined'))
          _buildLanguageAnalysisCard(statsData),
      ],
    );
  }

  Widget _buildTimeEstimate(String title, String time, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkTheme
                  ? ModernAppColors.darkTextPrimary
                  : ModernAppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ModernAppColors.statsGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDarkTheme
                  ? ModernAppColors.darkTextSecondary
                  : ModernAppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageAnalysisCard(Map<String, dynamic> statsData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernAppColors.statsPurple.withOpacity(0.1),
            ModernAppColors.statsOrange.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ModernAppColors.statsPurple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernAppColors.statsPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate,
                  color: ModernAppColors.statsPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Bilingual Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ModernAppColors.statsPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This version contains both English and Tamil text, providing a rich bilingual reading experience for deeper understanding and cross-cultural study.',
            style: TextStyle(
              fontSize: 16,
              color: isDarkTheme
                  ? ModernAppColors.darkTextSecondary
                  : ModernAppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingProgressSection(Map<String, dynamic> statsData) {
    final currentProgress = {
      'currentBook': selectedBookName.isNotEmpty ? selectedBookName : 'None',
      'currentChapter':
          selectedChapterDisplay.isNotEmpty ? selectedChapterDisplay : 'None',
      'bookProgress': selectedBookName.isNotEmpty
          ? ((currentChapterIndex + 1) / totalChapters * 100).toStringAsFixed(1)
          : '0',
      'totalBookmarks': savedReferences.length,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Your Reading Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkTheme
                      ? ModernAppColors.darkTextPrimary
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Current Reading Info
          _buildProgressInfo(
              '📖 Current Book', currentProgress['currentBook'].toString()),
          const SizedBox(height: 12),
          _buildProgressInfo('📄 Current Chapter',
              currentProgress['currentChapter'].toString()),
          const SizedBox(height: 12),
          _buildProgressInfo('🔖 Saved Bookmarks',
              '${currentProgress['totalBookmarks']} verses'),

          if (selectedBookName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Book Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentChapterIndex + 1) / totalChapters,
              backgroundColor: ModernAppColors.accentBlue.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  ModernAppColors.secondaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              '${currentProgress['bookProgress']}% complete',
              style: TextStyle(
                fontSize: 14,
                color: ModernAppColors.secondaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkTheme
                ? ModernAppColors.darkTextSecondary
                : ModernAppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkTheme
                  ? ModernAppColors.darkTextPrimary
                  : ModernAppColors.lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTestamentBreakdown(Map<String, dynamic> statsData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.cardGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Testament Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDarkTheme
                      ? ModernAppColors.darkTextPrimary
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Old Testament
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernAppColors.statsGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ModernAppColors.statsGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ModernAppColors.statsGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Old Testament',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme
                          ? ModernAppColors.darkTextPrimary
                          : ModernAppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  '${statsData['oldTestament']} books',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ModernAppColors.statsGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // New Testament
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ModernAppColors.statsBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ModernAppColors.statsBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ModernAppColors.statsBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New Testament',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme
                          ? ModernAppColors.darkTextPrimary
                          : ModernAppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  '${statsData['newTestament']} books',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ModernAppColors.statsBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for statistics calculation - Optimized for performance
  int _getTotalChapters() {
    return books.fold(
        0, (sum, book) => sum + book.findAllElements('CHAPTER').length);
  }

  int _getTotalVerses() {
    return books.fold(
        0, (sum, book) => sum + book.findAllElements('VERS').length);
  }

  int _getTotalWords() {
    int total = 0;
    for (final book in books) {
      for (final verse in book.findAllElements('VERS')) {
        // FIXED: Handle Combined Bible word counting properly
        String text = '';
        if (bibleName.contains('Combined')) {
          // Count words from both English and Tamil text
          if (verse.findElements('EN').isNotEmpty) {
            text += verse.findElements('EN').first.innerText.trim();
          }
          if (verse.findElements('TA').isNotEmpty) {
            text += ' ' + verse.findElements('TA').first.innerText.trim();
          }
        } else {
          text = verse.innerText.trim();
        }

        if (text.isNotEmpty) {
          total += text
              .split(RegExp(r'\s+'))
              .where((word) => word.isNotEmpty)
              .length;
        }
      }
    }
    return total;
  }

  Map<String, dynamic> _calculateDetailedStats() {
    final totalBooks = books.length;
    final totalChapters = _getTotalChapters();
    final totalVerses = _getTotalVerses();
    final totalWords = _getTotalWords();

    // Calculate averages
    final avgWordsPerChapter =
        totalChapters > 0 ? (totalWords / totalChapters) : 0.0;
    final avgWordsPerVerse = totalVerses > 0 ? (totalWords / totalVerses) : 0.0;
    final avgVersesPerChapter =
        totalChapters > 0 ? (totalVerses / totalChapters) : 0.0;

    // Testament breakdown (first 39 books are typically Old Testament)
    final oldTestament = totalBooks >= 39 ? 39 : totalBooks;
    final newTestament = totalBooks > 39 ? totalBooks - 39 : 0;

    return {
      'totalBooks': totalBooks,
      'totalChapters': totalChapters,
      'totalVerses': totalVerses,
      'totalWords': totalWords,
      'avgWordsPerChapter': avgWordsPerChapter,
      'avgWordsPerVerse': avgWordsPerVerse,
      'avgVersesPerChapter': avgVersesPerChapter,
      'oldTestament': oldTestament,
      'newTestament': newTestament,
    };
  }

  // Optimized number formatting
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

class BibleVersion {
  final String name;
  final String filePath;
  const BibleVersion({required this.name, required this.filePath});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibleVersion &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          filePath == other.filePath;

  @override
  int get hashCode => name.hashCode ^ filePath.hashCode;
}

// UPDATED: Enhanced search state management
class SearchState {
  final String query;
  final List<Map<String, String>> allResults;
  final List<Map<String, String>> displayedResults;
  final int currentPage;
  final ScrollController? scrollController;
  // ADDED: Position in the results list to preserve scroll position
  final double scrollPosition;

  SearchState({
    required this.query,
    required this.allResults,
    required this.displayedResults,
    required this.currentPage,
    this.scrollController,
    this.scrollPosition = 0.0,
  });

  SearchState copyWith({
    String? query,
    List<Map<String, String>>? allResults,
    List<Map<String, String>>? displayedResults,
    int? currentPage,
    ScrollController? scrollController,
    double? scrollPosition,
  }) {
    return SearchState(
      query: query ?? this.query,
      allResults: allResults ?? this.allResults,
      displayedResults: displayedResults ?? this.displayedResults,
      currentPage: currentPage ?? this.currentPage,
      scrollController: scrollController ?? this.scrollController,
      scrollPosition: scrollPosition ?? this.scrollPosition,
    );
  }
}

// UPDATED: Enhanced SearchResult class
class SearchResult {
  final SearchState searchState;
  final String? selectedVerse;

  SearchResult({
    required this.searchState,
    this.selectedVerse,
  });
}

// Enhanced Color extension for better dark mode support
extension ColorExtension on Color {
  /// Creates a new color with the provided values, keeping existing values for unspecified parameters
  Color withValues({double? red, double? green, double? blue, double? alpha}) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round() : this.alpha,
      red != null ? (red * 255).round() : this.red,
      green != null ? (green * 255).round() : this.green,
      blue != null ? (blue * 255).round() : this.blue,
    );
  }

  /// Creates a more visible variant of the color for dark mode
  Color get darkModeVariant {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  /// Creates a more visible variant of the color for light mode
  Color get lightModeVariant {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0)).toColor();
  }
}

// Performance optimization mixin
mixin PerformanceOptimizations {
  final Map<String, dynamic> _cache = {};

  T? getCached<T>(String key) => _cache[key] as T?;
  void setCached<T>(String key, T value) => _cache[key] = value;
  void clearCache() => _cache.clear();
}

// UPDATED: VerseSearchDelegate with proper state restoration and Combined Bible support
class VerseSearchDelegate extends SearchDelegate<SearchResult?> {
  final List<xml.XmlElement> books;
  final Function(String) oNSABveReference;
  final String bibleName;
  final double fontSize;
  final Color fontColor;
  final bool isDarkTheme;
  final SearchState? initialSearchState;
  final bool showResultsImmediately;

  late stt.SpeechToText _speech;
  bool _isListeningEnglish = false;
  bool _isListeningTamil = false;
  String _currentLanguage = 'en_US';

  // Enhanced state management
  Timer? _debounceTimer;
  bool _isSearching = false;
  static const int _resultsPerPage = 20;

  // Current search state
  SearchState _currentSearchState;
  final ScrollController _scrollController = ScrollController();

  // Track if search was manually triggered
  bool _hasSearched = false;
  String _lastSearchedQuery = '';

  VerseSearchDelegate({
    required this.books,
    required this.oNSABveReference,
    required this.bibleName,
    required this.fontSize,
    required this.fontColor,
    required this.isDarkTheme,
    this.initialSearchState,
    this.showResultsImmediately = false,
  }) : _currentSearchState = initialSearchState ??
            SearchState(
              query: '',
              allResults: [],
              displayedResults: [],
              currentPage: 0,
              scrollController: null,
            ) {
    _speech = stt.SpeechToText();

    // Initialize with provided state if it exists
    final initialSearchState = this.initialSearchState;
    if (initialSearchState != null) {
      query = initialSearchState.query;
      _currentSearchState = initialSearchState;
      _hasSearched = initialSearchState.query.isNotEmpty;
      _lastSearchedQuery = initialSearchState.query;

      // ADDED: Restore scroll position
      if (initialSearchState.scrollPosition > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(initialSearchState.scrollPosition);
          }
        });
      }
    }
  }

  @override
  String get searchFieldLabel => 'Search verses, words, or phrases...';

  @override
  TextStyle? get searchFieldStyle => TextStyle(
        color: isDarkTheme
            ? ModernAppColors.darkTextPrimary
            : ModernAppColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w400,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final backgroundColor = isDarkTheme
        ? ModernAppColors.darkBackground
        : ModernAppColors.lightBackground;

    final surfaceColor =
        isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
        titleTextStyle: TextStyle(
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        toolbarTextStyle: TextStyle(
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDarkTheme
              ? ModernAppColors.darkTextSecondary
              : ModernAppColors.lightTextSecondary,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: surfaceColor,
        filled: true,
      ),
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      cardColor: surfaceColor,
      dialogBackgroundColor: surfaceColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ModernAppColors.primaryBlue,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        surface: surfaceColor,
        background: backgroundColor,
      ).copyWith(
        surface: surfaceColor,
        background: backgroundColor,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isDarkTheme
                ? ModernAppColors.cardDark
                : ModernAppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDarkTheme
                    ? ModernAppColors.shadowDark
                    : ModernAppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.clear,
              color: isDarkTheme
                  ? ModernAppColors.darkTextPrimary
                  : ModernAppColors.lightTextPrimary,
            ),
            onPressed: () {
              query = '';
              _clearSearchState();
              _hasSearched = false;
              _lastSearchedQuery = '';
              showSuggestions(context);
            },
          ),
        ),
      if (query.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: ModernAppGradients.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ModernAppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              if (query.isNotEmpty) {
                _performManualSearch(query, context);
              }
            },
          ),
        ),
      Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: ModernAppGradients.secondaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ModernAppColors.secondaryBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.mic,
            color: Colors.white,
          ),
          onPressed: () {
            _showVoiceSearchDialog(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
        onPressed: () {
          _debounceTimer?.cancel();

          // UPDATED: Save scroll position when closing
          double scrollPos = 0.0;
          if (_scrollController.hasClients) {
            scrollPos = _scrollController.offset;
          }

          final updatedState = _currentSearchState.copyWith(
            scrollPosition: scrollPos,
          );

          close(context, SearchResult(searchState: updatedState));
        },
      ),
    );
  }

  void _performManualSearch(String searchQuery, BuildContext context) {
    if (searchQuery.isEmpty) return;

    _hasSearched = true;
    _lastSearchedQuery = searchQuery;

    setState(() {
      _isSearching = true;
    });

    Future.microtask(() {
      final allResults = _processSearchResults(searchQuery);
      final displayedResults = allResults.take(_resultsPerPage).toList();

      _currentSearchState = SearchState(
        query: searchQuery,
        allResults: allResults,
        displayedResults: displayedResults,
        currentPage: 0,
        scrollController: _scrollController,
      );

      setState(() {
        _isSearching = false;
      });

      showResults(context);
    });
  }

  void _clearSearchState() {
    _currentSearchState = SearchState(
      query: '',
      allResults: [],
      displayedResults: [],
      currentPage: 0,
      scrollController: _scrollController,
    );
  }

  void setState(VoidCallback fn) {
    fn();
  }

  void _showModernSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? ModernAppColors.error : ModernAppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVoiceSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkTheme
              ? ModernAppColors.cardDark
              : ModernAppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: ModernAppColors.shadowDark,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? ModernAppColors.darkTextSecondary
                        : ModernAppColors.lightTextSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Voice Search',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextPrimary
                        : ModernAppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildVoiceOption(context, true)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildVoiceOption(context, false)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceOption(BuildContext context, bool isEnglish) {
    bool isListening = isEnglish ? _isListeningEnglish : _isListeningTamil;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pop(context);
          _handleVoiceSearch(context, isEnglish);
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isListening
                ? ModernAppGradients.primaryGradient
                : ModernAppGradients.secondaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isListening
                        ? ModernAppColors.primaryBlue
                        : ModernAppColors.secondaryBlue)
                    .withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                isEnglish ? 'English' : 'தமிழ்',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEnglish ? 'Tap to speak' : 'பேச அழுத்தவும்',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rest of the VerseSearchDelegate methods continue in the next part...
  // UPDATED: buildSuggestions to handle immediate results display
  @override
  Widget buildSuggestions(BuildContext context) {
    // UPDATED: Show results immediately if flag is set (for back navigation)
    if (showResultsImmediately &&
        _hasSearched &&
        _currentSearchState.allResults.isNotEmpty) {
      return _buildRealTimeResults(context);
    }

    // Only show results if search was manually triggered
    if (_hasSearched &&
        query == _lastSearchedQuery &&
        _currentSearchState.allResults.isNotEmpty) {
      return _buildRealTimeResults(context);
    }

    // Always show search tips when typing (no auto-search)
    return _buildSearchTips(context);
  }

  Widget _buildSearchTips(BuildContext context) {
    return Container(
      color: isDarkTheme
          ? ModernAppColors.darkBackground
          : ModernAppColors.lightBackground,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 40),
                  _buildMainSearchCard(),
                  const SizedBox(height: 32),
                  _buildTipCard(
                    Icons.search,
                    'Press Search Button',
                    'Type your search term and press the search button to find results',
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    Icons.keyboard_alt_outlined,
                    'Search Examples',
                    'Try "love", "faith", "hope", or specific verses like "John 3:16"',
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    Icons.mic_outlined,
                    'Voice Search',
                    'Tap the microphone icon for hands-free searching',
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    Icons.bookmark_add_outlined,
                    'Save Results',
                    'Tap the bookmark icon to save verses for later',
                  ),
                  const SizedBox(height: 32),
                  _buildSuggestionsCard(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSearchCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ModernAppGradients.secondaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search the Bible',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDarkTheme
                  ? ModernAppColors.darkTextPrimary
                  : ModernAppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Type your search term and press the search button',
            style: TextStyle(
              fontSize: 16,
              color: isDarkTheme
                  ? ModernAppColors.darkTextSecondary
                  : ModernAppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // UPDATED: Add visual search button example
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: ModernAppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ModernAppGradients.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(height: 12),
          Text(
            'Quick Search Tips:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Type any word or phrase\n• Press the search button to find verses\n• Use voice search for hands-free input',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ModernAppColors.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: ModernAppColors.secondaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextPrimary
                        : ModernAppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextSecondary
                        : ModernAppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced real-time results with proper state management
  Widget _buildRealTimeResults(BuildContext context) {
    return Container(
      color: isDarkTheme
          ? ModernAppColors.darkBackground
          : ModernAppColors.lightBackground,
      child: SafeArea(
        child: Column(
          children: [
            _buildResultsHeader(),
            Expanded(
              child: _buildResultsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    final totalResults = _currentSearchState.allResults.length;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ModernAppGradients.secondaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isSearching && _currentSearchState.displayedResults.isEmpty
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSearching && _currentSearchState.displayedResults.isEmpty
                      ? 'Searching...'
                      : 'Search Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextPrimary
                        : ModernAppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isSearching && _currentSearchState.displayedResults.isEmpty
                      ? 'Please wait...'
                      : '$totalResults verses found for "$_lastSearchedQuery"',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme
                        ? ModernAppColors.darkTextSecondary
                        : ModernAppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!_isSearching && totalResults > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: ModernAppGradients.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                totalResults > 999 ? '999+' : '$totalResults',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced results list with proper pagination and state preservation
  Widget _buildResultsList(BuildContext context) {
    final displayResults = _currentSearchState.displayedResults;

    if (_isSearching && displayResults.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkTheme
                ? ModernAppColors.darkTextPrimary
                : ModernAppColors.lightTextPrimary,
          ),
        ),
      );
    }

    if (displayResults.isEmpty && _hasSearched) {
      return _buildNoResults();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isSearching &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200 &&
            _hasMoreResults()) {
          _loadMoreResults();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayResults.length + (_hasMoreResults() ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayResults.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkTheme
                        ? ModernAppColors.darkTextPrimary
                        : ModernAppColors.lightTextPrimary,
                  ),
                ),
              ),
            );
          }

          final result = displayResults[index];
          return _buildOptimizedSearchResultCard(context, result);
        },
      ),
    );
  }

  bool _hasMoreResults() {
    return _currentSearchState.displayedResults.length <
        _currentSearchState.allResults.length;
  }

  void _loadMoreResults() {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    final currentPage = _currentSearchState.currentPage + 1;
    final startIndex = currentPage * _resultsPerPage;
    final endIndex = (startIndex + _resultsPerPage)
        .clamp(0, _currentSearchState.allResults.length);

    final moreResults =
        _currentSearchState.allResults.sublist(startIndex, endIndex);

    _currentSearchState = _currentSearchState.copyWith(
      displayedResults: [
        ..._currentSearchState.displayedResults,
        ...moreResults
      ],
      currentPage: currentPage,
    );

    setState(() {
      _isSearching = false;
    });
  }

  Widget _buildOptimizedSearchResultCard(
      BuildContext context, Map<String, String> result) {
    final verseRef =
        '${result['book']} ${result['chapter']}:${result['verseNumber']}';
    final verseText = result['verseText'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(
        minHeight: 80,
      ),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ModernAppColors.accentBlue.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? ModernAppColors.shadowDark
                : ModernAppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // UPDATED: Save scroll position when selecting a verse
            double scrollPos = 0.0;
            if (_scrollController.hasClients) {
              scrollPos = _scrollController.offset;
            }

            final updatedState = _currentSearchState.copyWith(
              scrollPosition: scrollPos,
            );

            close(
                context,
                SearchResult(
                    searchState: updatedState, selectedVerse: verseRef));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ModernAppColors.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          verseRef,
                          style: const TextStyle(
                            color: ModernAppColors.secondaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ModernAppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.bookmark_add,
                          color: ModernAppColors.success,
                          size: 18,
                        ),
                        onPressed: () {
                          oNSABveReference(verseRef);
                          _showModernSnackBar(context, 'Saved $verseRef');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children:
                          _highlightOccurrences(verseText, _lastSearchedQuery),
                      style: TextStyle(
                        color: isDarkTheme
                            ? ModernAppColors.darkTextPrimary
                            : ModernAppColors.lightTextPrimary,
                        fontSize: fontSize.clamp(12.0, 18.0),
                        height: 1.5,
                      ),
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkTheme
                    ? ModernAppColors.cardDark
                    : ModernAppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDarkTheme
                        ? ModernAppColors.shadowDark
                        : ModernAppColors.shadowLight,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextPrimary
                    : ModernAppColors.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No verses found for "$_lastSearchedQuery"\nTry different keywords or check spelling',
              style: TextStyle(
                color: isDarkTheme
                    ? ModernAppColors.darkTextSecondary
                    : ModernAppColors.lightTextSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Show results immediately if we have them (for back navigation)
    if (showResultsImmediately && _currentSearchState.allResults.isNotEmpty) {
      return _buildRealTimeResults(context);
    }

    // Only show results if search was manually triggered
    if (_hasSearched && _currentSearchState.allResults.isNotEmpty) {
      return _buildRealTimeResults(context);
    }
    return _buildSearchTips(context);
  }

  void _handleVoiceSearch(BuildContext context, bool isEnglish) async {
    if (!_isListeningEnglish && !_isListeningTamil) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() {
              if (isEnglish) {
                _isListeningEnglish = false;
              } else {
                _isListeningTamil = false;
              }
            });
          }
        },
        onError: (val) {
          setState(() {
            if (isEnglish) {
              _isListeningEnglish = false;
            } else {
              _isListeningTamil = false;
            }
          });
          if (context.mounted) {
            _showModernSnackBar(context, 'Voice search error occurred',
                isError: true);
          }
        },
      );

      if (available) {
        setState(() {
          if (isEnglish) {
            _isListeningEnglish = true;
            _currentLanguage = 'en_US';
          } else {
            _isListeningTamil = true;
            _currentLanguage = 'ta_IN';
          }
        });

        _speech.listen(
          localeId: _currentLanguage,
          onResult: (val) {
            query = val.recognizedWords;
            showSuggestions(context);
            if (val.finalResult) {
              _stopListening();
              // UPDATED: Automatically search after voice input completes
              if (query.isNotEmpty) {
                _performManualSearch(query, context);
              }
              if (context.mounted) {
                _showModernSnackBar(
                    context, 'Voice search completed - searching now');
              }
            }
          },
        );
        if (context.mounted) {
          _showModernSnackBar(context, 'Listening... Speak now');
        }
      } else {
        if (context.mounted) {
          _showModernSnackBar(context, 'Voice search not available',
              isError: true);
        }
      }
    } else {
      _stopListening();
      if (context.mounted) {
        _showModernSnackBar(context, 'Voice search stopped');
      }
    }
  }

  void _stopListening() {
    if (_isListeningEnglish || _isListeningTamil) {
      _speech.stop();
      setState(() {
        _isListeningEnglish = false;
        _isListeningTamil = false;
      });
    }
  }

  List<TextSpan> _highlightOccurrences(String source, String query) {
    if (query.isEmpty) return [TextSpan(text: source)];

    var matches = <Match>[];
    String lowerSource = source.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final matchIndex = lowerSource.indexOf(lowerQuery, start);
      if (matchIndex == -1) break;
      matches.add(Match(matchIndex, matchIndex + query.length));
      start = matchIndex + query.length;
    }

    if (matches.isEmpty) return [TextSpan(text: source)];

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: source.substring(currentIndex, match.start),
          style: TextStyle(
            color: isDarkTheme
                ? ModernAppColors.darkTextPrimary
                : ModernAppColors.lightTextPrimary,
          ),
        ));
      }
      spans.add(TextSpan(
        text: source.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: ModernAppColors.warning.withOpacity(0.3),
          fontWeight: FontWeight.w700,
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
      ));
      currentIndex = match.end;
    }

    if (currentIndex < source.length) {
      spans.add(TextSpan(
        text: source.substring(currentIndex),
        style: TextStyle(
          color: isDarkTheme
              ? ModernAppColors.darkTextPrimary
              : ModernAppColors.lightTextPrimary,
        ),
      ));
    }

    return spans;
  }

  // FIXED: Enhanced search results processing for Combined Bible
  List<Map<String, String>> _processSearchResults(String query) {
    List<Map<String, String>> searchResults = [];
    if (query.isEmpty) return searchResults;

    bool isTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(query);
    final lowerQuery = query.toLowerCase();
    const maxResults = 1000;

    for (var book in books) {
      if (searchResults.length >= maxResults) break;

      String bookName = _getBookName(book);

      for (var chapter in book.findAllElements('CHAPTER')) {
        if (searchResults.length >= maxResults) break;

        String chapterNumber = chapter.getAttribute('cnumber') ?? '';

        for (var verse in chapter.findAllElements('VERS')) {
          if (searchResults.length >= maxResults) break;

          String verseNumber = verse.getAttribute('vnumber') ?? '';

          // FIXED: Enhanced text extraction for Combined Bible
          String searchText = '';
          String displayText = '';

          if (bibleName.contains('Combined')) {
            String enText = '';
            String taText = '';

            // Get English text
            if (verse.findElements('EN').isNotEmpty) {
              enText = verse.findElements('EN').first.innerText.trim();
            }

            // Get Tamil text
            if (verse.findElements('TA').isNotEmpty) {
              taText = verse.findElements('TA').first.innerText.trim();
            }

            // Search in appropriate text based on query language
            if (isTamil) {
              searchText = taText;
              displayText = taText.isNotEmpty ? taText : enText;
            } else {
              searchText = enText;
              displayText = enText.isNotEmpty
                  ? (taText.isNotEmpty ? '$enText\n\nTamil: $taText' : enText)
                  : taText;
            }
          } else {
            // For single language Bibles
            if (verse.findElements('EN').isNotEmpty) {
              searchText = verse.findElements('EN').first.innerText.trim();
            } else {
              searchText = verse.innerText.trim();
            }
            displayText = searchText;
          }

          if (searchText.isEmpty) continue;

          // Perform case-insensitive search
          bool matches = isTamil
              ? searchText.contains(query)
              : searchText.toLowerCase().contains(lowerQuery);

          if (matches) {
            searchResults.add({
              'book': bookName,
              'chapter': chapterNumber,
              'verseNumber': verseNumber,
              'verseText': displayText,
            });
          }
        }
      }
    }

    return searchResults;
  }

  // FIXED: Enhanced book name extraction for Combined Bible
  String _getBookName(xml.XmlElement book) {
    if (bibleName.contains('Combined')) {
      final enName = book.getAttribute('bname_en')?.trim() ?? '';
      final taName = book.getAttribute('bname_ta')?.trim() ?? '';

      // Handle cases where one or both names might be empty
      if (enName.isEmpty && taName.isEmpty) {
        return 'Unknown Book';
      } else if (enName.isEmpty) {
        return taName;
      } else if (taName.isEmpty) {
        return enName;
      } else {
        return '$enName / $taName';
      }
    } else if (bibleName == 'Tamil Bible') {
      return book.getAttribute('bname_ta')?.trim() ??
          book.getAttribute('bname')?.trim() ??
          'Unknown Book';
    } else {
      // For English Bibles
      return book.getAttribute('bname_en')?.trim() ??
          book.getAttribute('bname')?.trim() ??
          'Unknown Book';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

class Match {
  final int start;
  final int end;
  const Match(this.start, this.end);
}
