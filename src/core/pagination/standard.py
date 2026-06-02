from rest_framework.pagination import PageNumberPagination


class StandardResultsPagination(PageNumberPagination):
    """
    Phân trang chuẩn toàn hệ thống.
    Query params: ?page=1&page_size=20
    Tối đa 100 records / trang.
    """
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100
    page_query_param = "page"
