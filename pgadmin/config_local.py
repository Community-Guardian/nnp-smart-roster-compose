# pgAdmin reverse proxy configuration
# This file configures pgAdmin to work properly behind nginx reverse proxy

import os

# Set the script name for reverse proxy
SCRIPT_NAME = '/pgadmin'

# Configure application root
APPLICATION_ROOT = '/pgadmin'

# Fix cookie settings for reverse proxy
SESSION_COOKIE_PATH = '/pgadmin'
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True

# CSRF settings for reverse proxy
WTF_CSRF_TIME_LIMIT = None

# Configure preferred URL scheme
PREFERRED_URL_SCHEME = 'https'

# Fix redirects
SEND_FILE_MAX_AGE_DEFAULT = 31536000

# Authentication settings
AUTHENTICATION_SOURCES = ['internal']

# Default server group
DEFAULT_SERVER_GROUP = 'Servers'

# Console settings
CONSOLE_LOG_LEVEL = 20

# Email configuration (if needed)
MAIL_SERVER = 'localhost'
MAIL_PORT = 587
MAIL_USE_TLS = True

# Override any other settings as needed
DATA_DIR = '/var/lib/pgadmin'
LOG_FILE = '/dev/stdout'
