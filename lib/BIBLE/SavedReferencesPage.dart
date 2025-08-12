import 'package:flutter/material.dart';
import 'package:bible/BIBLE/BibleReaderHome.dart';
import 'package:intl/intl.dart';

class SavedReferencesPage extends StatefulWidget {
  final List<Map<String, String>> savedReferences;
  final Function(String) getVerseDetails;
  final Function(String) onGoToVerse;
  final Function(String) onDeleteReference;
  final bool isDarkTheme;

  const SavedReferencesPage({
    super.key,
    required this.savedReferences,
    required this.getVerseDetails,
    required this.onGoToVerse,
    required this.onDeleteReference,
    required this.isDarkTheme,
  });

  @override
  SavedReferencesPageState createState() => SavedReferencesPageState();
}

class SavedReferencesPageState extends State<SavedReferencesPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Formats the saved date in Indian format (dd/MM/yyyy hh:mm a)
  String formatDate(String dateString) {
    try {
      DateTime dt = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy hh:mm a').format(dt);
    } catch (e) {
      return dateString;
    }
  }

  void _showModernSnackBar(String message, {bool isError = false}) {
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? ModernAppColors.error : ModernAppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = widget.isDarkTheme
        ? ModernAppGradients.backgroundDarkGradient
        : ModernAppGradients.backgroundLightGradient;

    return Scaffold(
      appBar: _buildModernAppBar(),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.savedReferences.isEmpty
                ? _buildEmptyState()
                : _buildSavedReferencesList(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Text(
        'Saved References',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: widget.isDarkTheme 
              ? ModernAppColors.darkTextPrimary 
              : ModernAppColors.lightTextPrimary,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: widget.isDarkTheme
              ? ModernAppGradients.backgroundDarkGradient
              : ModernAppGradients.backgroundLightGradient,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isDarkTheme 
              ? ModernAppColors.cardDark 
              : ModernAppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkTheme 
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
            color: widget.isDarkTheme 
                ? ModernAppColors.darkTextPrimary 
                : ModernAppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        if (widget.savedReferences.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: widget.isDarkTheme 
                  ? ModernAppColors.cardDark 
                  : ModernAppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkTheme 
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
                _showInfoDialog();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.isDarkTheme 
                  ? ModernAppColors.cardDark 
                  : ModernAppColors.cardLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkTheme 
                      ? ModernAppColors.shadowDark 
                      : ModernAppColors.shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 64,
              color: widget.isDarkTheme 
                  ? ModernAppColors.darkTextSecondary 
                  : ModernAppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Bookmarks Saved',
            style: TextStyle(
              color: widget.isDarkTheme 
                  ? ModernAppColors.darkTextPrimary 
                  : ModernAppColors.lightTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save verses by long-pressing them while reading',
            style: TextStyle(
              color: widget.isDarkTheme 
                  ? ModernAppColors.darkTextSecondary 
                  : ModernAppColors.lightTextSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedReferencesList() {
    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Your Bookmarks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: widget.isDarkTheme 
                      ? ModernAppColors.darkTextPrimary 
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.secondaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.savedReferences.length} saved',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List of saved references
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.savedReferences.length,
            itemBuilder: (context, index) {
              final reference = widget.savedReferences[index]['reference']!;
              final date = widget.savedReferences[index]['date']!;
              final formattedDate = formatDate(date);
              
              return _buildModernReferenceCard(
                reference, 
                formattedDate, 
                index
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernReferenceCard(String reference, String formattedDate, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDarkTheme 
            ? ModernAppColors.cardDark 
            : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkTheme 
                ? ModernAppColors.shadowDark 
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showVerseDetails(reference),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: ModernAppGradients.secondaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bookmark,
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
                            reference,
                            style: TextStyle(
                              color: widget.isDarkTheme 
                                  ? ModernAppColors.darkTextPrimary 
                                  : ModernAppColors.lightTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: widget.isDarkTheme 
                                    ? ModernAppColors.darkTextSecondary 
                                    : ModernAppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Saved on $formattedDate',
                                style: TextStyle(
                                  color: widget.isDarkTheme 
                                      ? ModernAppColors.darkTextSecondary 
                                      : ModernAppColors.lightTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.chrome_reader_mode,
                      label: 'Go to Verse',
                      onTap: () => widget.onGoToVerse(reference),
                      isPrimary: true,
                    ),
                    _buildActionButton(
                      icon: Icons.visibility,
                      label: 'Preview',
                      onTap: () => _showVerseDetails(reference),
                      isPrimary: false,
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      onTap: () => _confirmDelete(reference),
                      isPrimary: false,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isPrimary && !isDestructive 
                ? ModernAppGradients.primaryGradient 
                : null,
            color: !isPrimary 
                ? (isDestructive 
                    ? ModernAppColors.error.withValues(alpha: 0.1)
                    : ModernAppColors.accentBlue.withValues(alpha: 0.1))
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isDestructive && !isPrimary
                ? Border.all(color: ModernAppColors.error.withValues(alpha: 0.3))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary 
                    ? Colors.white
                    : (isDestructive 
                        ? ModernAppColors.error 
                        : ModernAppColors.secondaryBlue),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPrimary 
                      ? Colors.white
                      : (isDestructive 
                          ? ModernAppColors.error 
                          : (widget.isDarkTheme 
                              ? ModernAppColors.darkTextPrimary 
                              : ModernAppColors.lightTextPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerseDetails(String reference) {
    final verseDetails = widget.getVerseDetails(reference);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkTheme 
              ? ModernAppColors.cardDark 
              : ModernAppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verse Details',
                  style: TextStyle(
                    color: widget.isDarkTheme 
                        ? ModernAppColors.darkTextPrimary 
                        : ModernAppColors.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ModernAppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reference,
                  style: const TextStyle(
                    color: ModernAppColors.secondaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                verseDetails,
                style: TextStyle(
                  color: widget.isDarkTheme 
                      ? ModernAppColors.darkTextPrimary 
                      : ModernAppColors.lightTextPrimary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: ModernAppColors.accentBlue.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: ModernAppColors.secondaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: ModernAppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Go to Verse',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onGoToVerse(reference);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String reference) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkTheme 
              ? ModernAppColors.cardDark 
              : ModernAppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernAppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: ModernAppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Bookmark',
                  style: TextStyle(
                    color: widget.isDarkTheme 
                        ? ModernAppColors.darkTextPrimary 
                        : ModernAppColors.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this bookmark? This action cannot be undone.',
            style: TextStyle(
              color: widget.isDarkTheme 
                  ? ModernAppColors.darkTextSecondary 
                  : ModernAppColors.lightTextSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: ModernAppColors.accentBlue.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: ModernAppColors.secondaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: ModernAppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      widget.onDeleteReference(reference);
                      Navigator.of(context).pop();
                      _showModernSnackBar('Bookmark deleted successfully');
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkTheme 
              ? ModernAppColors.cardDark 
              : ModernAppColors.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Bookmarks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Tap on any bookmark card to preview the verse. Use the action buttons to navigate to the verse or delete bookmarks. Long-press verses while reading to save new bookmarks.',
            style: TextStyle(
              color: widget.isDarkTheme 
                  ? ModernAppColors.darkTextSecondary 
                  : ModernAppColors.lightTextSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: ModernAppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}
