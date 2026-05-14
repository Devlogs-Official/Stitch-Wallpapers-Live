class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasMore,
  });

  final List<T> items;
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool hasMore;
}
