import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:prime_school/api_service.dart';
import 'package:prime_school/homework/homework_detail_page.dart';
import 'package:prime_school/homework/homework_page.dart';

bool _isDownloading = false;
String formatDate(String? inputDate) {
  if (inputDate == null || inputDate.isEmpty) return '';
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(inputDate));
  } catch (_) {
    return inputDate;
  }
}

// ====================================================
// 📥 SAFE FILE DOWNLOAD (iOS + Android)
// ====================================================
Future<void> downloadFile(BuildContext context, String filePath) async {
  if (_isDownloading) return;
  _isDownloading = true;

  final fullUrl = ApiService.getFullUrl(filePath);

  try {
    final fileName = fullUrl.split('/').last;
    final dio = Dio();
    late String savePath;

    // ================= ANDROID =================
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      savePath = '${downloadsDir.path}/$fileName';

      await dio.download(fullUrl, savePath);

      // ✅ Preview open
      await OpenFile.open(savePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & Preview opened")),
        );
      }
    }

    // ================= iOS =================
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      savePath = '${dir.path}/$fileName';

      await dio.download(fullUrl, savePath);

      // ✅ Preview open
      await OpenFile.open(savePath);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  } finally {
    _isDownloading = false;
  }
}

// ====================================================
// 📝 RECENT HOMEWORKS WIDGET
// ====================================================
Widget buildRecentHomeworks(
  BuildContext context,
  List<Map<String, dynamic>> homeworks,
) {
  final limitedHomeworks = homeworks.take(3).toList();

  return Container(
    padding: const EdgeInsets.all(10),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F8CFF), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Recent Homework",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Latest assignments",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeworkPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.08),
                  border: Border.all(color: AppColors.primary.withOpacity(.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "View All",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// Empty State
        if (limitedHomeworks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 6),
                Text(
                  "No homework available",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: limitedHomeworks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final hw = limitedHomeworks[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeworkDetailPage(homework: hw),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      /// Icon
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.book_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// Homework Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hw['HomeworkTitle'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    formatDate(hw['SubmissionDate']),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// Download
                      if (hw['Attachment'] != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            downloadFile(context, hw['Attachment']);
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
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),

                      const SizedBox(width: 4),

                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey.shade500,
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
