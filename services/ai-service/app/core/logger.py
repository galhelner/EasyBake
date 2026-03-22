import logging
from pathlib import Path


def get_logger() -> logging.Logger:
    logger = logging.getLogger("ai_service")
    if logger.handlers:
        return logger

    project_root = Path(__file__).resolve().parents[2]
    logs_dir = project_root / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)

    class UppercaseFormatter(logging.Formatter):
        def format(self, record):
            record.levelname = record.levelname.upper()
            return super().format(record)

    formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)

    file_handler = logging.FileHandler(logs_dir / "ai-service.log", encoding="utf-8")
    file_handler.setFormatter(formatter)

    logger.setLevel(logging.INFO)
    logger.addHandler(stream_handler)
    logger.addHandler(file_handler)
    logger.propagate = False

    return logger