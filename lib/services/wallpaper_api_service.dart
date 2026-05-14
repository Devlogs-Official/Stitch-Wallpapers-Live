import 'package:dio/dio.dart';

import '../models/paginated_response.dart';
import '../models/wallpaper_model.dart';

class WallpaperApiService {
  WallpaperApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.devlogs.pro/apps/stitchWallpapers',
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;

  Future<PaginatedResponse<WallpaperModel>> getWallpapers({
    required bool isLive,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '/get_stitch_wallpapers.php',
        queryParameters: <String, dynamic>{
          'is_live': isLive ? 1 : 0,
          'page': pageNumber,
          'page_size': pageSize,
        },
      );

      final Map<String, dynamic> body = _asMap(response.data);

      if (body['status'] != true) {
        throw Exception(body['message']?.toString() ?? 'Failed to fetch wallpapers.');
      }

      final List<dynamic> wallpapersRaw =
          body['data'] is List<dynamic> ? body['data'] as List<dynamic> : <dynamic>[];

      final List<WallpaperModel> items = wallpapersRaw
          .whereType<Map<String, dynamic>>()
          .map(WallpaperModel.fromJson)
          .toList(growable: false);

      final Map<String, dynamic> pagination = _asMap(body['pagination']);
      final int currentPage = _readInt(pagination['current_page']) ?? pageNumber;
      final int parsedPageSize = _readInt(pagination['page_size']) ?? pageSize;
      final int totalRecords = _readInt(pagination['total_records']) ?? items.length;
      final int totalPages = _readInt(pagination['total_pages']) ??
          ((parsedPageSize <= 0) ? 1 : ((totalRecords + parsedPageSize - 1) ~/ parsedPageSize));

      return PaginatedResponse<WallpaperModel>(
        items: items,
        currentPage: currentPage,
        pageSize: parsedPageSize,
        totalRecords: totalRecords,
        totalPages: totalPages <= 0 ? 1 : totalPages,
        hasMore: currentPage < (totalPages <= 0 ? 1 : totalPages),
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch wallpapers: ${_extractDioMessage(e)}');
    } catch (e) {
      throw Exception('Failed to fetch wallpapers: $e');
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((dynamic key, dynamic val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static int? _readInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '');
  }

  static String _extractDioMessage(DioException e) {
    final dynamic data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'];
      if (message != null) {
        return message.toString();
      }
    }
    return e.message ?? 'Network request failed.';
  }
}
