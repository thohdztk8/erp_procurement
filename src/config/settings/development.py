from .base import *  # noqa

DEBUG = True
CORS_ALLOW_ALL_ORIGINS = True  # Cho phép mọi origin trong dev

# Log SQL queries ra console
LOGGING["loggers"]["django.db.backends"] = {  # noqa
    "handlers": ["console"],
    "level": "DEBUG",
    "propagate": False,
}

# Email in ra console thay vì gửi thật
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Django Debug Toolbar (chỉ load nếu đã cài)
try:
    import debug_toolbar  # noqa: F401

    INSTALLED_APPS += ["debug_toolbar"]  # noqa: F405
    MIDDLEWARE.insert(1, "debug_toolbar.middleware.DebugToolbarMiddleware")  # noqa: F405
    INTERNAL_IPS = ["127.0.0.1"]
except ImportError:
    pass
