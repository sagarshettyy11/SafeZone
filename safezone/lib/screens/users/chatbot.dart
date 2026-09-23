import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safezone/constants/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromBot;
  final DateTime time;
  _ChatMessage(this.text, {required this.fromBot}) : time = DateTime.now();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  static const String kDefaultCity = "Mangaluru";

  @override
  void initState() {
    super.initState();
    _botSay(
      "👋 Hello! I'm SafeZone AI Assistant.\n\n"
      "I can assist you with real-time safety advisories, emergency protocols, and reporting guidance.\n\n"
      "Try asking one of the suggestions below or type 'SOS' for immediate danger help.",
    );
  }

  void _botSay(String text) {
    if (mounted) {
      setState(() {
        _messages.insert(0, _ChatMessage(text, fromBot: true));
        _isTyping = false;
      });
    }
  }

  void _userSay(String text) {
    if (mounted) {
      setState(() {
        _messages.insert(0, _ChatMessage(text, fromBot: false));
        _isTyping = true;
      });
    }
  }

  Future<void> _handleSendMessage([String? presetText]) async {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty) return;
    if (presetText == null) _controller.clear();

    _userSay(text);

    final lower = text.toLowerCase();

    // Instant SOS detection without delay
    if (lower.contains('sos') || lower.contains('help') || lower.contains('emergency')) {
      _botSay(
        "🚨 EMERGENCY DETECTED!\n\n"
        "• Call Police: 112 or 100\n"
        "• Call Ambulance: 108\n"
        "• Trigger your Emergency SOS from the home screen to send live GPS coordinates and record video evidence.\n"
        "• Move towards a brightly lit, public location immediately.",
      );
      return;
    }

    if (lower.contains('harass') || lower.contains('stalk')) {
      _botSay(
        "🛡️ Harassment Safety Advisory:\n\n"
        "1. Prioritize physical safety and head into an open shop, station, or group of people.\n"
        "2. Keep your phone ready on SafeZone SOS.\n"
        "3. You can file an official incident report under 'File Complaint' with photos or vehicle plate numbers.",
      );
      return;
    }

    if (lower.contains('safe') || lower.contains('area') || lower.contains('route')) {
      _botSay(
        "🗺️ Area Safety Check for $kDefaultCity:\n\n"
        "Based on verified community reports:\n"
        "• Well-lit arterial roads and metro hubs are active & monitored.\n"
        "• Isolated spots near poorly lit alleys are marked as warnings on your Safety Map tab.\n"
        "• Keep live tracking shared with your emergency contact.",
      );
      return;
    }

    // Default response
    await Future.delayed(const Duration(milliseconds: 600));
    _botSay(
      "Thank you for contacting SafeZone Assistant. If you witness or experience any suspicious behavior, please file an incident report or use the SOS button for instant emergency dispatch.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SafeZone AI",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Online & Protecting",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Prompt suggestions
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildPromptChip("🚨 Emergency SOS Help", () => _handleSendMessage("Emergency SOS")),
                const SizedBox(width: 8),
                _buildPromptChip("📍 Is this area safe?", () => _handleSendMessage("Is this area safe?")),
                const SizedBox(width: 8),
                _buildPromptChip("⚠️ How to report harassment?", () => _handleSendMessage("How to report harassment?")),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Messages List
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "SafeZone AI is thinking...",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask about area safety or report issues...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.divider,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _handleSendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isBot = msg.fromBot;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isBot ? AppColors.surface : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 4 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 4),
          ),
          border: isBot ? Border.all(color: AppColors.border) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isBot ? AppColors.textPrimary : Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
