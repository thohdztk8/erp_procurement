FROM python:3.12-slim

# ── System deps: ODBC driver cho pyodbc/mssql-django ────────
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl gnupg2 unixodbc unixodbc-dev libgssapi-krb5-2 \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
       | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft.gpg] \
       https://packages.microsoft.com/debian/12/prod bookworm main" \
       > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
       msodbcsql18 mssql-tools18 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/opt/mssql-tools18/bin"

WORKDIR /app

# ── Python dependencies ──────────────────────────────────────
COPY requirements/base.txt /tmp/base.txt
COPY requirements/production.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# ── Source code ──────────────────────────────────────────────
COPY src/ /app/

# ── Directories & permissions ────────────────────────────────
RUN mkdir -p /app/media /app/staticfiles \
    && chmod +x /app/scripts/entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--timeout", "120", \
     "--access-logfile", "-"]