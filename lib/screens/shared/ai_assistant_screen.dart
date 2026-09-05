import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart'; 
import '../../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  final String role;

  const AIAssistantScreen({super.key, required this.role});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    String welcomeText = widget.role == 'admin' 
        ? 'Bonjour Administrateur ! \n\nJe suis votre assistant IA spécialisé dans les manuels de maintenance.\n\n•  Je consulte la documentation technique\n• 🔧 Je réponds aux questions sur les procédures\n•  Je t\'aide dans la gestion du parc'
        : 'Bonjour Responsable ! \n\nJe suis votre assistant IA pour la maintenance.\n\n•  J\'accède aux manuels des ascenseurs\n•  Je t\'aide pour les interventions techniques\n•  Je réponds à tes questions opérationnelles';

    setState(() {
      _messages.add({'isUser': false, 'text': welcomeText});
    });
  }

  Future<void> _sendMessage() async {
  if (_controller.text.trim().isEmpty || _isLoading) return;

  final userMessage = _controller.text.trim();
  _controller.clear();

  setState(() {
    _messages.add({'isUser': true, 'text': userMessage});
    _isLoading = true;
  });

  _scrollToBottom();

  try {
    print(' Envoi de la requête à: ${ApiConfig.ragApiUrl}');
    print(' Question: $userMessage');
    print(' API Key: ${ApiConfig.ragApiKey}');

    final response = await http.post(
      Uri.parse(ApiConfig.ragApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': ApiConfig.ragApiKey,
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'question': userMessage,
       
      }),
    );

    print(' Status Code: ${response.statusCode}');
    print(' Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(' Données décodées: $data');
      
      // L'API RAG peut renvoyer la réponse dans différents champs
      String aiResponse = data['answer'] ?? 
                         data['response'] ?? 
                         data['result'] ?? 
                         data['message'] ?? 
                         data['data'] ?? 
                         'Information not found';

      if (aiResponse == 'Information not found' || aiResponse.isEmpty) {
        print('⚠️ Réponse non trouvée. Corps complet: ${response.body}');
      }

      setState(() {
        _messages.add({'isUser': false, 'text': aiResponse});
      });
    } else if (response.statusCode == 429) {
      setState(() {
        _messages.add({'isUser': false, 'text': '️ Trop de requêtes. Attendez quelques secondes avant de poser une nouvelle question.'});
      });
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      setState(() {
        _messages.add({'isUser': false, 'text': ' Clé API invalide ou expirée. Status: ${response.statusCode}'});
      });
    } else {
      setState(() {
        _messages.add({'isUser': false, 'text': 'Erreur serveur (${response.statusCode}):\n${response.body}'});
      });
    }
  } catch (e, stackTrace) {
    print(' Erreur réseau: $e');
    print(' Stack trace: $stackTrace');
    setState(() {
      _messages.add({'isUser': false, 'text': 'Erreur réseau : $e\n\nVérifiez:\n1. Votre connexion internet\n2. Que l\'URL ${ApiConfig.ragApiUrl} est accessible\n3. Que la clé API est correcte'});
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }
}

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assistant IA', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'Base de connaissance RAG',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg['isUser'], msg['text']);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.smart_toy, color: AppColors.orange, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('L\'IA consulte la documentation...', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Posez votre question technique...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: IconButton(
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.only(right: 8),
              child: const Icon(Icons.smart_toy, color: AppColors.orange, size: 18),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))
                  : MarkdownBody(
                      data: text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.4),
                        listBullet: const TextStyle(color: AppColors.orange),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}