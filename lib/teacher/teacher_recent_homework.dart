import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prime_school/api_service.dart';
import 'package:prime_school/teacher/teacher_homework_detail_page.dart';
import 'package:prime_school/teacher/teacher_homework_page.dart';

class TeacherRecentHomeworks extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;

  const TeacherRecentHomeworks({super.key, required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final limitedHomeworks = homeworks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "Recent Homeworks",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),

              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherHomeworkPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          limitedHomeworks.isEmpty
              ? const Text("No homeworks available.")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedHomeworks.length,
                  itemBuilder: (context, index) {
                    final hw = limitedHomeworks[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherHomeworkDetailPage(homework: hw),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.book_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hw['HomeworkTitle'] ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          formatDate(hw['SubmissionDate']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if ((hw['Remark'] ?? "")
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      hw['Remark'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            Column(
                              children: [
                                if ((hw['Attachment'] ?? "")
                                    .toString()
                                    .isNotEmpty)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      final attachment = hw['Attachment'];

                                      debugPrint(
                                        "🟡 RAW ATTACHMENT: $attachment",
                                      );

                                      if (attachment == null ||
                                          attachment.toString().isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Attachment not available",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final String fileUrl =
                                          ApiService.getFullUrl(
                                            attachment.toString(),
                                          );

                                      debugPrint(
                                        "✅ FINAL DOWNLOAD URL: $fileUrl",
                                      );

                                      _downloadFile(context, fileUrl);
                                    },
                                    child: Container(
                                      height: 30,
                                      width: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.download_rounded,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
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
        ],
      ),
    );
  }

  // ---------------- SAFE FILE DOWNLOAD ----------------
  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attachment not available")));
      return;
    }

    try {
      debugPrint("⬇️ Downloading: $url");

      final response = await http.get(Uri.parse(url));
      debugPrint("📡 RESPONSE STATUS: ${response.statusCode}");
      debugPrint("📦 RESPONSE LENGTH: ${response.bodyBytes.length}");
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Failed to download file");
      }

      final fileName = Uri.parse(url).pathSegments.last;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        // ✅ Real user-visible Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final filePath = '${downloadsDir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        await OpenFile.open(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File saved to Downloads folder")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        await OpenFile.open(filePath); // Files app
      }
    } catch (e) {
      debugPrint("❌ Teacher HW download error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  // ---------------- DATE FORMAT ----------------
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    try {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day.toString().padLeft(2, '0')}-"
          "${parsedDate.month.toString().padLeft(2, '0')}-"
          "${parsedDate.year}";
    } catch (_) {
      return date;
    }
  }
}
