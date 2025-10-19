import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


class GeminiService {
  final String apiKey = 'AIzaSyCBfvNpqu4vrbodttgPjKwSE8qdPQePkow'; // Replace with your actual key

  Future<Map<String, dynamic>> getTaskDetails(String taskName) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemma-3n-e4b-it:generateContent?key=$apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final prompt = '''
You are an intelligent reward system for a gamified productivity app. Assign a coin value to each new user task based on the following criteria:

- Difficulty (harder tasks = more coins)
- Estimated time to complete (longer = more coins)
- Importance/impact (more important = more coins)
- Rarity (tasks done less often = more coins)

Shop items cost around 600 coins, so a typical daily task should give enough coins that a user can buy an item after about 15-20 tasks. Most tasks should be worth between 10 and 30 coins, but very hard or rare tasks can be worth up to 40 coins. Never assign more than 40 coins to any task.

**Examples:**
- “Drink a glass of water” → Category: Health, Coins: 10
- “Take out the trash” → Category: Chores, Coins: 12
- “Read 10 pages of a book” → Category: Learning, Coins: 15
- “Do 20 push-ups” → Category: Fitness, Coins: 16
- “Write a daily journal entry” → Category: Mindfulness, Coins: 18
- “Study for 30 minutes” → Category: Study, Coins: 20
- “Clean your room” → Category: Chores, Coins: 22
- “Write a 2-page report” → Category: Work, Coins: 28
- “Run 5km” → Category: Fitness, Coins: 32
- “Prepare tax documents” → Category: Work, Coins: 38
- “Complete a major project milestone” → Category: Work, Coins: 40

Return only in this format:
Category: [Category]
Coins: [Number]

Task: $taskName
''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output = data['candidates'][0]['content']['parts'][0]['text'];

      final categoryMatch = RegExp(r'Category:\s*(.+)').firstMatch(output);
      final coinsMatch = RegExp(r'Coins:\s*(\d+)').firstMatch(output);

      return {
        'category': categoryMatch?.group(1) ?? 'General',
        'coins': int.tryParse(coinsMatch?.group(1) ?? '5') ?? 5,
      };
    } else {
      debugPrint('❌ Gemini API error: ${response.statusCode}');
      debugPrint(response.body);
      return {
        'category': 'General',
        'coins': 5,
      };
    }
  }

  Future<Map<String, dynamic>> getCategoryStyle(String category) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final headers = {'Content-Type': 'application/json'};

    final prompt = '''
You are a style engine for a habit-tracking app. You MUST follow these rules exactly.

1.  **Analyze the category**: "$category"
2.  **Select ONE icon and ONE color** from the options provided below.

**DO NOT DEVIATE. YOU MUST USE THE EXACT VALUES FROM THE LISTS.**

---
### ICONS (USE EXACT NAMES)
`work_outline`, `school_outlined`, `lightbulb_outline`, `favorite_outline`, `monitor_heart_outlined`, `water_drop_outlined`, `medication_outlined`, `fitness_center`, `directions_run`, `sports_esports_outlined`, `self_improvement_outlined`, `psychology_outlined`, `bedtime_outlined`, `menu_book_outlined`, `palette_outlined`, `music_note_outlined`, `code`, `camera_alt_outlined`, `restaurant_outlined`, `pets_outlined`, `home_outlined`, `shopping_cart_outlined`, `smart_toy`

### COLORS (USE VIBRANT HEX CODES)
-   **Vibrant Reds**: `#D32F2F`, `#C62828`
-   **Energetic Blues**: `#1976D2`, `#1E88E5`
-   **Deep Purples**: `#512DA8`, `#673AB7`
-   **Creative Pinks**: `#AD1457`, `#C2185B`
-   **Modern Cyans**: `#00838F`, `#006064`
-   **Warm Oranges**: `#F57C00`, `#EF6C00`
-   **Professional Greys**: `#455A64`, `#37474F`

---

### **RESPONSE FORMAT (MUST BE EXACT):**

Icon: [ICON_NAME_FROM_LIST]
Color: [HEX_CODE_FROM_LIST]
''';
    final body = jsonEncode({
      "contents": [{"parts": [{"text": prompt}]}]
    });
    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output = data['candidates'][0]['content']['parts'][0]['text'];
      debugPrint('Gemini Style Response for "$category":\n$output');

      final iconMatch = RegExp(r'Icon:\s*([\w_]+)').firstMatch(output);
      final colorMatch = RegExp(r'Color:\s*(#[A-Fa-f0-9]{6})').firstMatch(output);

      return {
        'icon': iconMatch?.group(1) ?? 'smart_toy',
        'color': colorMatch?.group(1) ?? '#607D8B',
      };
    } else {
      debugPrint('❌ Gemini API error: ${response.statusCode}\n${response.body}');
      return {'icon': 'smart_toy', 'color': '#607D8B'};
    }
  }

  Future<Map<String, dynamic>> getTaskAndCategoryStyle(
      String taskName, List<String> knownCategories) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemma-3n-e4b-it:generateContent?key=$apiKey');

    final headers = {
      'Content-Type': 'application/json',
    };

    final knownList = knownCategories.isEmpty ? 'none' : knownCategories.join(', ');
    final prompt = '''
You are an AI expert in habit tracking and task categorization. Analyze the task and provide appropriate categorization and reward.

1. CATEGORY SELECTION RULES:
   - If task matches existing category ([$knownList]), USE IT
   - Otherwise, choose from these standard categories:
     Work, Study, Fitness, Health, Mindfulness, Reading, Art, Music, Coding, Sleep

   CATEGORIZATION EXAMPLES:
   "Read book" → Reading
   "Code project" → Coding
   "Exercise" → Fitness
   "Meditate" → Mindfulness
   "Write report" → Work
   "Study math" → Study
   "Practice piano" → Music
   "Draw sketch" → Art
   "Go to bed early" → Sleep
   "Take vitamins" → Health

2. COIN REWARD RULES:
   High Reward (7-10 coins):
   - Time-consuming tasks (>1 hour)
   - Complex activities
   - High effort requirements
   Examples: "Work out for 2 hours" (9), "Complete project milestone" (8)

   Medium Reward (4-6 coins):
   - Regular daily tasks
   - Moderate effort
   - 30-60 minute activities
   Examples: "Read for 30 minutes" (5), "Practice instrument" (6)

   Low Reward (2-3 coins):
   - Quick tasks (<15 minutes)
   - Simple habits
   - Minimal effort required
   Examples: "Drink water" (2), "Take medication" (3)

RESPONSE FORMAT:
Category: [CATEGORY_NAME]
Coins: [2-10]

Task: $taskName
''';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output = data['candidates'][0]['content']['parts'][0]['text'];

      final categoryMatch = RegExp(r'Category:\s*(.+)').firstMatch(output);
      final coinsMatch = RegExp(r'Coins:\s*(\d+)').firstMatch(output);
      final colorMatch = RegExp(r'Color:\s*(#[A-Fa-f0-9]{6})').firstMatch(output);
      final iconMatch = RegExp(r'Icon:\s*([\w_]+)').firstMatch(output);

      return {
        'category': categoryMatch?.group(1) ?? 'General',
        'coins': int.tryParse(coinsMatch?.group(1) ?? '5') ?? 5,
        'color': colorMatch?.group(1),
        'icon': iconMatch?.group(1),
      };
    } else {
      debugPrint('❌ Gemini API error: ${response.statusCode}');
      debugPrint(response.body);
      return {
        'category': 'General',
        'coins': 5,
      };
    }
  }
}
