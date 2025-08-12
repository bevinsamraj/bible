import 'package:bible/BIBLE/BibleReaderHome.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final double fontSize;
  final bool isDarkTheme;
  final Function(double) onFontSizeChanged;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.fontSize,
    required this.isDarkTheme,
    required this.onFontSizeChanged,
    required this.onThemeChanged,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  
  late double _fontSize;
  late bool _isDarkTheme;
  final double _minFontSize = 12.0;
  final double _maxFontSize = 30.0;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _isDarkTheme = widget.isDarkTheme;
    _initAnimations();
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
    final bgGradient = _isDarkTheme
        ? ModernAppGradients.backgroundDarkGradient
        : ModernAppGradients.backgroundLightGradient;

    return Scaffold(
      appBar: _buildModernAppBar(),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSettingsContent(),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Text(
        'Settings',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _isDarkTheme 
              ? ModernAppColors.darkTextPrimary 
              : ModernAppColors.lightTextPrimary,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: _isDarkTheme
              ? ModernAppGradients.backgroundDarkGradient
              : ModernAppGradients.backgroundLightGradient,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkTheme 
              ? ModernAppColors.cardDark 
              : ModernAppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _isDarkTheme 
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
            color: _isDarkTheme 
                ? ModernAppColors.darkTextPrimary 
                : ModernAppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: _isDarkTheme 
                ? ModernAppColors.cardDark 
                : ModernAppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isDarkTheme 
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

  Widget _buildSettingsContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _isDarkTheme 
                      ? ModernAppColors.darkTextPrimary 
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize your reading experience',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkTheme 
                      ? ModernAppColors.darkTextSecondary 
                      : ModernAppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        // Settings Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFontSizeCard(),
              const SizedBox(height: 20),
              _buildThemeToggleCard(),
              const SizedBox(height: 20),
              _buildPreviewCard(),
              const SizedBox(height: 20),
              _buildInfoCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeCard() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme 
                ? ModernAppColors.shadowDark 
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernAppGradients.secondaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.text_fields,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _isDarkTheme 
                              ? ModernAppColors.darkTextPrimary 
                              : ModernAppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Adjust text size for comfortable reading',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDarkTheme 
                              ? ModernAppColors.darkTextSecondary 
                              : ModernAppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Font size value display
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: ModernAppGradients.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ModernAppColors.primaryBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${_fontSize.toInt()}pt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Font size controls
            Row(
              children: [
                _buildFontButton(
                  icon: Icons.remove,
                  onPressed: _fontSize > _minFontSize
                      ? () {
                          setState(() {
                            _fontSize = (_fontSize - 1).clamp(_minFontSize, _maxFontSize);
                          });
                          widget.onFontSizeChanged(_fontSize);
                          _showModernSnackBar('Font size decreased');
                        }
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: ModernAppColors.secondaryBlue,
                        inactiveTrackColor: ModernAppColors.accentBlue.withValues(alpha: 0.3),
                        thumbColor: ModernAppColors.primaryBlue,
                        overlayColor: ModernAppColors.primaryBlue.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: _minFontSize,
                        max: _maxFontSize,
                        divisions: (_maxFontSize - _minFontSize).toInt(),
                        onChanged: (double value) {
                          setState(() {
                            _fontSize = value;
                          });
                          widget.onFontSizeChanged(value);
                        },
                        onChangeEnd: (value) {
                          _showModernSnackBar('Font size updated to ${value.toInt()}pt');
                        },
                      ),
                    ),
                  ),
                ),
                _buildFontButton(
                  icon: Icons.add,
                  onPressed: _fontSize < _maxFontSize
                      ? () {
                          setState(() {
                            _fontSize = (_fontSize + 1).clamp(_minFontSize, _maxFontSize);
                          });
                          widget.onFontSizeChanged(_fontSize);
                          _showModernSnackBar('Font size increased');
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick font size options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickFontButton('Small', 14.0),
                _buildQuickFontButton('Medium', 18.0),
                _buildQuickFontButton('Large', 24.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontButton({required IconData icon, required VoidCallback? onPressed}) {
    bool isEnabled = onPressed != null;
    
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled ? ModernAppGradients.primaryGradient : null,
        color: !isEnabled 
            ? (_isDarkTheme ? ModernAppColors.darkTextSecondary : ModernAppColors.lightTextSecondary).withValues(alpha: 0.2)
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: ModernAppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : (_isDarkTheme ? ModernAppColors.darkTextSecondary : ModernAppColors.lightTextSecondary),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFontButton(String label, double size) {
    bool isSelected = _fontSize == size;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _fontSize = size;
          });
          widget.onFontSizeChanged(size);
          _showModernSnackBar('Font size set to $label');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? ModernAppColors.secondaryBlue 
                : ModernAppColors.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? null 
                : Border.all(color: ModernAppColors.accentBlue.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : ModernAppColors.secondaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleCard() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme 
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
          onTap: () {
            setState(() {
              _isDarkTheme = !_isDarkTheme;
            });
            widget.onThemeChanged(_isDarkTheme);
            _showModernSnackBar(_isDarkTheme ? 'Dark theme enabled' : 'Light theme enabled');
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _isDarkTheme 
                        ? ModernAppGradients.primaryGradient 
                        : ModernAppGradients.secondaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _isDarkTheme 
                              ? ModernAppColors.darkTextPrimary 
                              : ModernAppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        _isDarkTheme ? 'Dark theme is enabled' : 'Light theme is enabled',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDarkTheme 
                              ? ModernAppColors.darkTextSecondary 
                              : ModernAppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isDarkTheme,
                  activeColor: ModernAppColors.secondaryBlue,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkTheme = value;
                    });
                    widget.onThemeChanged(value);
                    _showModernSnackBar(value ? 'Dark theme enabled' : 'Light theme enabled');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkTheme ? ModernAppColors.cardDark : ModernAppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme 
                ? ModernAppColors.shadowDark 
                : ModernAppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ModernAppGradients.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.preview,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Text Preview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _isDarkTheme 
                        ? ModernAppColors.darkTextPrimary 
                        : ModernAppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (_isDarkTheme 
                    ? ModernAppColors.lightBackground 
                    : ModernAppColors.darkBackground).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ModernAppColors.accentBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John 3:16',
                    style: TextStyle(
                      color: ModernAppColors.secondaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
                    style: TextStyle(
                      color: _isDarkTheme 
                          ? ModernAppColors.darkTextPrimary 
                          : ModernAppColors.lightTextPrimary,
                      fontSize: _fontSize,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ModernAppGradients.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ModernAppColors.secondaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.tips_and_updates,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 16),
            const Text(
              'Settings Tips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your settings are automatically saved. Changes will apply immediately across the app for a better reading experience.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkTheme 
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
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings Help',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(Icons.text_fields, 'Font Size', 'Adjust the text size for comfortable reading. Use the slider or quick buttons.'),
              const SizedBox(height: 16),
              _buildHelpItem(Icons.brightness_6, 'Theme', 'Switch between light and dark themes to reduce eye strain.'),
              const SizedBox(height: 16),
              _buildHelpItem(Icons.save, 'Auto Save', 'All settings are automatically saved and applied immediately.'),
            ],
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

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ModernAppColors.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ModernAppColors.secondaryBlue,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _isDarkTheme 
                      ? ModernAppColors.darkTextPrimary 
                      : ModernAppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkTheme 
                      ? ModernAppColors.darkTextSecondary 
                      : ModernAppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
