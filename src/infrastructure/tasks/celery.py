"""
Celery application instance.
Import trong các task file: from infrastructure.tasks.celery import app
"""
import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")

app = Celery("procurement")

# Đọc cấu hình từ Django settings (prefix CELERY_)
app.config_from_object("django.conf:settings", namespace="CELERY")

# Tự động discover tasks trong tất cả INSTALLED_APPS
app.autodiscover_tasks()

# Explicit include cho tasks nằm ngoài INSTALLED_APPS
# (infrastructure/tasks/ không phải Django app nên autodiscover không tìm thấy)
app.conf.include = [
    "infrastructure.tasks.email_tasks",
]
