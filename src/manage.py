#!/usr/bin/env python
import os
import sys


def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.development")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Django không tìm thấy. Kiểm tra PYTHONPATH và virtual env."
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
