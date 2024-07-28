import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk Clipboard.
import 'package:flutter_markdown/flutter_markdown.dart'; // Import untuk mendukung format Markdown.
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Salin pesan ke clipboard saat ditekan lama.
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pesan disalin ke clipboard'),
        ));
      },
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'KAMU' : 'AI',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.0,
            ),
          ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color:
                    isUser ? Color.fromRGBO(206, 126, 13, 1) : Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: isUser
                  ? Text(
                      message,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    )
                  : MarkdownBody(
                      data:
                          message, // Menggunakan MarkdownBody untuk merender teks AI.
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 16.0, color: Colors.black),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({Key? key}) : super(key: key);

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with AutomaticKeepAliveClientMixin {
  bool isThinking = false;
  List<String> datas = [];
  late GenerativeModel model;
  final controller = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  setModel() {
    model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyAdPjhdNyOMLu5euc5NkJ5r0610Czf2kCE',
    );
  }

  @override
  void initState() {
    super.initState();
    setModel();
    loadConversation().then((loadedConversation) {
      setState(() {
        datas.addAll(loadedConversation);
      });
    });
  }

  void saveConversation(List<String> conversation) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('conversation', conversation);
  }

  Future<List<String>> loadConversation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? conversation = prefs.getStringList('conversation');
    return conversation ?? [];
  }

  /// Fungsi untuk mendapatkan prompt dari model AI dan menyertakan riwayat percakapan.
  Future<void> getPrompt(String message) async {
    try {
      datas.add(message); // Menyimpan pesan pengguna
      saveConversation(datas);
      controller.clear();
      setState(() {
        isThinking = true;
      });

      // Gabungkan seluruh riwayat percakapan sebagai konteks
      final conversationHistory = datas.join('\n');

      // Sertakan riwayat percakapan dalam prompt
      final content = [Content.text(conversationHistory)];
      final response = await model.generateContent(content);
      String aiResponse = response.text ?? "";

      // Menyimpan pesan balasan AI yang telah dimodifikasi
      datas.add(aiResponse);
      saveConversation(datas);
      setState(() {
        isThinking = false;
      });
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Terjadi kesalahan: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        isThinking = false;
      });
      print('Error: $e');
    }
  }

  void clearChat() {
    setState(() {
      datas.clear();
      saveConversation(datas); // Kosongkan juga percakapan yang disimpan.
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Let's keep the state alive
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Halo! Selamat datang di AI Chat'),
          backgroundColor: Color.fromARGB(255, 230, 230, 230),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline_sharp),
              onPressed: clearChat,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Scrollbar(
                  child: ListView(
                    padding: EdgeInsets.only(
                        right: 8.0), // Tambahkan padding di sebelah kanan
                    shrinkWrap: true,
                    children: datas
                        .map(
                          (e) => ChatBubble(
                            message: e,
                            isUser: datas.indexOf(e) % 2 == 0,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            Container(
              color: Color.fromRGBO(255, 255, 255, 1),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(10.10),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20.0),
                          color: Colors.grey[800],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20.0),
                            onTap: () {
                              // Menambahkan aksi ketika kotak pesan ditekan.
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: TextField(
                                      controller: controller,
                                      enabled: !isThinking,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Ketik sesuatu...',
                                        hintStyle:
                                            TextStyle(color: Colors.white70),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (message) {
                                        if (!isThinking) {
                                          getPrompt(message);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.send,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  onPressed: isThinking
                                      ? null
                                      : () {
                                          getPrompt(controller.text);
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    isThinking
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(116, 179, 0, 0)),
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
