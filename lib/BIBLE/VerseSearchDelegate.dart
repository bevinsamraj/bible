// // lib/bible/verse_search_delegate.dart

import 'package:bible/BIBLE/BibleReaderHome.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

// UPDATED: VerseSearchDelegate with proper state restoration
class VerseSearchDelegate extends SearchDelegate<SearchResult?> {
  final List<xml.XmlElement> books;
  final Function(String) onSaveReference;
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
    required this.onSaveReference,
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

  // UPDATED: buildSuggestions to handle immediate results display
  @override
  Widget buildSuggestions(BuildContext context) {
    // UPDATED: Show results immediately if flag is set (for back navigation)
    if (showResultsImmediately && _hasSearched && _currentSearchState.allResults.isNotEmpty) {
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
                      : '$totalResults verses found for "${_lastSearchedQuery}"',
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

    final moreResults = _currentSearchState.allResults.sublist(startIndex, endIndex);

    _currentSearchState = _currentSearchState.copyWith(
      displayedResults: [..._currentSearchState.displayedResults, ...moreResults],
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
                          onSaveReference(verseRef);
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
                _showModernSnackBar(context, 'Voice search completed - searching now');
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
          String verseText = verse.innerText.trim();

          if (verseText.isEmpty) continue;

          bool matches = isTamil
              ? verseText.contains(query)
              : verseText.toLowerCase().contains(lowerQuery);

          if (matches) {
            searchResults.add({
              'book': bookName,
              'chapter': chapterNumber,
              'verseNumber': verseNumber,
              'verseText': verseText,
            });
          }
        }
      }
    }

    return searchResults;
  }

  String _getBookName(xml.XmlElement book) {
    switch (bibleName) {
      case 'Combined':
        final enName = book.getAttribute('bname_en') ?? '';
        final taName = book.getAttribute('bname_ta') ?? '';
        return '$enName / $taName';
      case 'Tamil Bible':
        return book.getAttribute('bname') ?? 'Unknown Book';
      default:
        return book.getAttribute('bname') ?? 'Unknown Book';
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
