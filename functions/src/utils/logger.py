import logging
from firebase_functions import logger as firebase_logger

# Configure standard logging to work with Cloud Functions
logging.basicConfig(level=logging.INFO)

class Logger:
    @staticmethod
    def info(message, payload=None):
        firebase_logger.info(message, payload)

    @staticmethod
    def error(message, payload=None):
        firebase_logger.error(message, payload)

    @staticmethod
    def warning(message, payload=None):
        firebase_logger.warn(message, payload)

    @staticmethod
    def debug(message, payload=None):
        firebase_logger.debug(message, payload)
