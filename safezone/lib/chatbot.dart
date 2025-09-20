import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ------------------------------
/// SAFEZONE CHATBOT (STEP 1)
/// ------------------------------
/// What this file does now:
/// 1) Minimal chat UI (no extra packages needed).
/// 2) Calls OpenAI GPT (gpt-4o-mini) to extract intent & craft a short reply.
/// 3) Simple confirm flow for incident reports, then saves to Supabase `incidents` table.
///
/// Prereqs you must have elsewhere in your app:
/// - Call `Supabase.initialize(...)` in main.dart BEFORE running the app.
/// - Create table `incidents` in Supabase (see SQL at the bottom of this file).
/// - Put your OpenAI API key & (optionally) a default city for better prompts.
///
/// Next steps we can add after you test this:
/// - SOS flow + trusted contacts table
/// - Location picker / GPS capture
/// - Media upload to Supabase Storage
/// - Multilingual prompts (Kannada/Hindi)

// ====== CONFIG ======
const String kOpenAiApiKey = "YOUR_OPENAI_API_KEY";
const String kOpenAiModel = "gpt-4o-mini"; // inexpensive, good for intent JSON
const String kDefaultCity =
    "Mangaluru"; // optional, helps GPT understand places

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromBot;
  final DateTime at;
  _ChatMessage(this.text, {required this.fromBot}) : at = DateTime.now();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  /// When the user starts a report, we store pending details here and wait for "confirm".
  Map<String, dynamic>? _pendingReport;

  @override
  void initState() {
    super.initState();
    _botSay(
      "👋 Hi! I'm SafeZone Assistant.\n"
      "I can help you report incidents, check area safety, or handle SOS.\n\n"
      "Try: ‘Report harassment near bus stand’, ‘Is Kankanady safe?’, or type ‘SOS’.",
    );
  }

  void _botSay(String text) {
    setState(() => _messages.insert(0, _ChatMessage(text, fromBot: true)));
  }

  void _userSay(String text) {
    setState(() => _messages.insert(0, _ChatMessage(text, fromBot: false)));
  }

  Future<void> _onSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    _userSay(text);

    // 1) Quick emergency local catch (no API latency for SOS keywords)
    final lower = text.toLowerCase();
    if (lower.contains('sos') ||
        lower.contains('help') ||
        lower.contains('emergency')) {
      _botSay(
        "🚨 Emergency detected! For now, this demo shows guidance. Next step we’ll wire live location & trusted contacts.\n"
        "• Call Police: 112\n• Stay in lit, public area\n• Share live location with a trusted contact",
      );
      return;
    }

    // 2) If we have a pending report, allow confirm/cancel without an API call
    if (_pendingReport != null) {
      if (lower == 'confirm') {
        await _saveIncidentToSupabase(_pendingReport!);
        _pendingReport = null;
        _botSay(
          "✅ Report submitted. Thank you for helping make $kDefaultCity safer.",
        );
        return;
      } else if (lower == 'cancel') {
        _pendingReport = null;
        _botSay(
          "❎ Okay, I canceled that report. You can start a new one anytime.",
        );
        return;
      }
    }

    // 3) Otherwise, ask GPT to classify the message & propose a short reply
    try {
      final parsed = await _callGptForIntent(text);

      final intent = (parsed['intent'] ?? '').toString();
      final reply = (parsed['reply'] ?? '').toString();

      if (intent == 'report_incident' || intent == 'report_infra_issue') {
        // Store pending details and ask for user confirmation
        _pendingReport = parsed;
        _botSay(
          '${reply.isNotEmpty ? "$reply\n\n" : ""}If that looks correct, type \'confirm\' to submit or \'cancel\' to discard.',
        );
        return;
      }

      if (intent == 'check_area_safety') {
        // For now, just echo reply. Next step we’ll query Supabase around GPS.
        _botSay(
          reply.isEmpty ? 'I\'ll check recent reports for that area.' : reply,
        );
        return;
      }

      if (intent == 'emergency_help') {
        _botSay(
          "🚨 I'm here. Use ‘SOS’ anytime. In the next step, we'll auto-share your live location to trusted contacts.",
        );
        return;
      }

      // Default smalltalk/unknown
      _botSay(
        reply.isEmpty
            ? "I'm here to help with safety, reporting, or SOS."
            : reply,
      );
    } catch (e) {
      _botSay("⚠️ I had trouble understanding that. Please try again.");
    }
  }

  Future<Map<String, dynamic>> _callGptForIntent(String userMessage) async {
    if (kOpenAiApiKey.isEmpty || kOpenAiApiKey == 'YOUR_OPENAI_API_KEY') {
      throw Exception('OpenAI API key not set.');
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final systemPrompt =
        '''
You are SafeZone Assistant. Extract the user's intent for a community safety app.
ALWAYS respond as STRICT JSON with these keys:
{
  "intent": "report_incident | report_infra_issue | emergency_help | check_area_safety | smalltalk",
  "incident_type": "theft | harassment | assault | suspicious_activity | accident | vandalism | infra_broken_streetlight | infra_open_manhole | infra_pothole | other | null",
  "location_text": "string or null",
  "when_text": "string or null",
  "description": "short clean summary of what happened (<= 25 words)",
  "needs_confirmation": true,
  "reply": "concise helpful message to the user (<= 40 words)"
}
Rules:
- If user asks area safety, set intent=check_area_safety and fill location_text if mentioned.
- If incident/infrastructure issue, set intent accordingly and include a concise description.
- Keep reply short and calm. Do NOT add extra fields. Do NOT write prose outside JSON.
Context city: $kDefaultCity.
''';

    final body = jsonEncode({
      'model': kOpenAiModel,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.2,
      'max_tokens': 220,
    });

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $kOpenAiApiKey',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('OpenAI error: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    // content should be JSON (response_format enforces it). Parse safely.
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    return parsed;
  }

  Future<void> _saveIncidentToSupabase(Map<String, dynamic> parsed) async {
    final client = Supabase.instance.client;

    final type = (parsed['incident_type'] ?? 'other').toString();
    final desc = (parsed['description'] ?? '').toString();
    final locText = (parsed['location_text'] ?? '').toString();
    final whenText = (parsed['when_text'] ?? '').toString();

    await client.from('incidents').insert({
      'type': type,
      'description': desc,
      'location_text': locText.isEmpty ? null : locText,
      'when_text': whenText.isEmpty ? null : whenText,
      'anonymous': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'SafeZone Chatbot',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E4DE8),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final bubbleColor = m.fromBot
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12);
                  final align = m.fromBot
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end;
                  final radius = BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: m.fromBot
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                    bottomRight: m.fromBot
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                  );
                  return Column(
                    crossAxisAlignment: align,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: radius,
                        ),
                        child: Text(
                          m.text,
                          style: m.fromBot
                              ? GoogleFonts.poppins(
                                  // font for bot messages
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                )
                              : GoogleFonts.roboto(
                                  // font for user messages (optional)
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _onSend, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================
   Supabase table (run once):
   ==========================

-- Enable UUIDs if not already
create extension if not exists "uuid-ossp";

create table if not exists public.incidents (
  id uuid primary key default uuid_generate_v4(),
  type text,
  description text,
  location_text text,
  when_text text,
  anonymous boolean default true,
  created_at timestamptz default now()
);

-- Optional: simple RLS example (tweak to your needs)
alter table public.incidents enable row level security;
create policy "insert_incidents_anon" on public.incidents
  for insert to anon with check (true);
create policy "read_incidents_public" on public.incidents
  for select using (true);
*/
