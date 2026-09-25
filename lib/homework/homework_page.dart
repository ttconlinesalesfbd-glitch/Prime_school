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

  // =========================
  // 📥 SAFE FILE DOWNLOAD
  // =========================
  Future<void> downloadFile(BuildContext context, String attachment) async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      // ✅ Safe URL resolve (no hardcode)
      final fullUrl = ApiService.getFullUrl(attachment);

      final fileName = fullUrl.split('/').last;

      debugPrint("⬇️ Download URL: $fullUrl");

      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW OPEN
        await OpenFile.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & preview opened")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW OPEN
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("❌ download error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No Homework Available",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "New assignments will appear here.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final hw = homeworks[index];
                final attachmentUrl = hw['Attachment'];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeworkDetailPage(homework: hw),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Left Icon
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hw['HomeworkTitle'] ?? "Homework",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "📅 ${formatDate(hw['WorkDate'])}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "⏰ ${formatDate(hw['SubmissionDate'])}",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if ((hw['Remark'] ?? "")
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),

                                Text(
                                  hw['Remark'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        /// Right Side
                        Column(
                          children: [
                            if (attachmentUrl != null)
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  downloadFile(context, attachmentUrl);
                                },
                                child: Container(
                                  height: 34,
                                  width: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.download_rounded,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
