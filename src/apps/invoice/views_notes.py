from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination.standard import StandardResultsPagination
from core.permissions.rbac import require_permission
from core.utils.code_generator import generate_document_code

from .models import CreditNote, DebitNote
from .serializers import (
    CreditNoteSerializer,
    CreditNoteCreateSerializer,
    DebitNoteSerializer,
    DebitNoteCreateSerializer,
)


class CreditNoteListCreateView(APIView):
    """
    GET /api/v2/credit-notes -> lấy danh sách
    POST /api/v2/credit-notes -> tạo mới
    """
    permission_classes = [IsAuthenticated, require_permission("INV_CREDIT_NOTE")]

    def get(self, request):
        qs = CreditNote.objects.select_related("supplier", "invoice").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(CreditNoteSerializer(page, many=True).data)

    def post(self, request):
        serializer = CreditNoteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        code = generate_document_code("CN", CreditNote, "credit_note_code")
        credit_note = CreditNote.objects.create(
            credit_note_code=code,
            credit_note_number=d["credit_note_number"],
            supplier_id=d["supplier_id"],
            invoice_id=d["invoice_id"],
            return_order_id=d.get("return_id"),
            credit_amount_before_tax=d["credit_amount_before_tax"],
            credit_tax_amount=d["credit_tax_amount"],
            credit_total_amount=d["credit_total_amount"],
            credit_date=d["credit_date"],
            reason=d["reason"],
            credit_pdf_path=d.get("credit_pdf_path"),
            applied_status="PENDING",
        )

        return Response(
            {
                "message": f"Credit Note {credit_note.credit_note_code} đã được tạo.",
                "data": CreditNoteSerializer(credit_note).data,
            },
            status=status.HTTP_201_CREATED,
        )


class DebitNoteListCreateView(APIView):
    """
    GET /api/v2/debit-notes -> lấy danh sách
    POST /api/v2/debit-notes -> tạo mới
    """
    permission_classes = [IsAuthenticated, require_permission("INV_DEBIT_NOTE")]

    def get(self, request):
        qs = DebitNote.objects.select_related("supplier", "invoice").order_by("-created_at")
        paginator = StandardResultsPagination()
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(DebitNoteSerializer(page, many=True).data)

    def post(self, request):
        serializer = DebitNoteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        code = generate_document_code("DN", DebitNote, "debit_note_code")
        debit_note = DebitNote.objects.create(
            debit_note_code=code,
            debit_note_number=d["debit_note_number"],
            supplier_id=d["supplier_id"],
            invoice_id=d["invoice_id"],
            debit_amount=d["debit_amount"],
            debit_date=d["debit_date"],
            reason=d["reason"],
            debit_pdf_path=d.get("debit_pdf_path"),
            applied_status="PENDING",
        )

        return Response(
            {
                "message": f"Debit Note {debit_note.debit_note_code} đã được tạo.",
                "data": DebitNoteSerializer(debit_note).data,
            },
            status=status.HTTP_201_CREATED,
        )
