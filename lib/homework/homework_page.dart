import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:prime_school/api_service.dart';
import 'package:prime_school/homework/homework_detail_page.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<dynamic> homeworks = [];
  bool isLoading = true;
  bool _isDownloading = false; // 🔒 download lock

  @override
  void initState() {
    super.initState();
    fetchHomework();
  }

  // =========================
  // 📡 FETCH HOMEWORK
  // =========================
  Future<void> fetchHomework() async {
    try {
      final response = await ApiService.post(context, '/student/homework');

      // 🔴 Token expired / auto logout
      if (response == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          homeworks = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load homework");
      }
    } catch (e) {
      debugPrint("❌ fetchHomework error: $e");

      if (!mounted) return;
      setState(() {
        isLoading = false;
        homeworks = [];
      });
    }
  }

  // =========================
  // 📅 DATE FORMAT
  // =========================
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> downloadFile(BuildContext context, String attachment) async {
    if (_isDownloading) return;

    _isDownloading = true;

    try {
      print("=========== DOWNLOAD DEBUG ===========");
      print("ATTACHMENT => $attachment");

      final fullUrl = ApiService.getFullUrl(attachment);

      print("FULL URL => $fullUrl");

      final fileName = fullUrl.split('/').last;

      print("FILE NAME => $fileName");

      final dir = await getApplicationDocumentsDirectory();

      print("SAVE DIRECTORY => ${dir.path}");

      final savePath = '${dir.path}/$fileName';

      print("SAVE PATH => $savePath");

      final response = await http.get(Uri.parse(fullUrl));

      print("DOWNLOAD STATUS => ${response.statusCode}");
      print("FILE SIZE => ${response.bodyBytes.length}");

      if (response.statusCode != 200) {
        throw Exception("Server Error: ${response.statusCode}");
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception("Empty file received");
      }

      final file = File(savePath);

      await file.writeAsBytes(response.bodyBytes, flush: true);

      print("FILE SAVED SUCCESSFULLY");

      final openResult = await OpenFile.open(savePath);

      print("OPEN FILE RESULT => ${openResult.message}");

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Downloaded & Preview Opened")),
      );
    } catch (e, stack) {
      print("=========== DOWNLOAD ERROR ===========");
      print(e);
      print(stack);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Download Failed: $e")));
    } finally {
      _isDownloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeworks', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : homeworks.isEmpty
          ? const Center(child: Text("No homework available"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final hw = homeworks[index];
                final attachmentUrl = hw['Attachment'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeworkDetailPage(homework: hw),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw['HomeworkTitle'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "📅 ${formatDate(hw['WorkDate'])}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  "Submission: ${formatDate(hw['SubmissionDate'])}",
                                  style: const TextStyle(fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if ((hw['Remark'] ?? '').isNotEmpty)
                            Text(
                              "📝 ${(hw['Remark'] as String).length > 150 ? hw['Remark'].substring(0, 150) + '...' : hw['Remark']}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          if (attachmentUrl != null)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  downloadFile(context, attachmentUrl);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
