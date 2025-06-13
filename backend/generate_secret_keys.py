import secrets

# Generate secure JWT keys
print("JWT_SECRET_KEY =", secrets.token_urlsafe(48))
print("JWT_REFRESH_SECRET_KEY =", secrets.token_urlsafe(48))
