# app/utils/id_utils.py
from __future__ import annotations
from datetime import datetime, timedelta, timezone
try:
    from zoneinfo import ZoneInfo  # stdlib 3.9+
except ImportError:  # very old Python
    ZoneInfo = None  # type: ignore

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

# Try to load IANA zone; if tzdata is missing (common on Windows), fall back to UTC+4.
def _get_mauritius_tz():
    if ZoneInfo is not None:
        try:
            return ZoneInfo("Africa/Mauritius")  # correct IANA key
        except Exception as e:
            _blue(f"[id_utils] ZoneInfo load failed ({e}); falling back to UTC+4")
    return timezone(timedelta(hours=4))  # fixed offset fallback

_MRU_TZ = _get_mauritius_tz()

def make_mru_id(dt: datetime | None = None) -> str:
    """
    Returns ID like DDMMYY_HHMM using Mauritius local time.
    Example: 230825_2012 (23 Aug 2025, 20:12 MRU)
    """
    now = (dt or datetime.utcnow().replace(tzinfo=timezone.utc)).astimezone(_MRU_TZ)
    return now.strftime("%d%m%y_%H%M")
