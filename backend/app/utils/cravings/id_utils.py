from __future__ import annotations
from datetime import datetime, timedelta, timezone
try:
    from zoneinfo import ZoneInfo 
except ImportError:  
    ZoneInfo = None  

BLUE = "\x1B[34m"; RESET = "\x1B[0m"
def _blue(msg: str) -> None:
    print(f"{BLUE}{msg}{RESET}")

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
