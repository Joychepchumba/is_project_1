import os
import secrets
import jwt
from jwt import InvalidTokenError, ExpiredSignatureError
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# JWT Configuration using environment variables
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 60 * 24 * 7))  # 7 days
ALGORITHM = "HS256"
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY")

# Development fallback (optional)
if not JWT_SECRET_KEY:
    JWT_SECRET_KEY = secrets.token_urlsafe(48)
    print(f"Generated JWT_SECRET_KEY: {JWT_SECRET_KEY}")

if not JWT_REFRESH_SECRET_KEY:
    JWT_REFRESH_SECRET_KEY = secrets.token_urlsafe(48)
    print(f"Generated JWT_REFRESH_SECRET_KEY: {JWT_REFRESH_SECRET_KEY}")

# Decode token function
def decodeJWT(jwtoken: str):
    try:
        payload = jwt.decode(jwtoken, JWT_SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except ExpiredSignatureError:
        print("Token has expired")
        return None
    except InvalidTokenError as e:
        print(f"Invalid token: {e}")
        return None
    except Exception as e:
        print(f"Token decode error: {e}")
        return None

# JWTBearer class to protect routes
class JWTBearer(HTTPBearer):
    def __init__(self, auto_error: bool = True):
        super(JWTBearer, self).__init__(auto_error=auto_error)

    async def __call__(self, request: Request):
        print(f"Auth header: {request.headers.get('authorization')}")

        credentials: HTTPAuthorizationCredentials = await super(JWTBearer, self).__call__(request)
        if credentials:
            print(f"Scheme: '{credentials.scheme}'")
            print(f"Token preview: {credentials.credentials[:20]}...")

            if credentials.scheme != "Bearer":
                print("Wrong scheme")
                raise HTTPException(status_code=403, detail="Invalid authentication scheme.")

            if not self.verify_jwt(credentials.credentials):
                print("Token verification failed")
                raise HTTPException(status_code=403, detail="Invalid or expired token.")

            print(" Auth successful")
            return credentials.credentials
        else:
            print("No credentials")
            raise HTTPException(status_code=403, detail="Invalid authorization code.")

    def verify_jwt(self, jwtoken: str) -> bool:
        """
        Verify JWT token and return True if valid, False otherwise
        """
        try:
            payload = jwt.decode(jwtoken, JWT_SECRET_KEY, algorithms=[ALGORITHM])
            print(f"Token valid. User ID: {payload.get('sub')}, Type: {payload.get('user_type')}")
            return True
        except ExpiredSignatureError:
            print("Token expired")
            return False
        except InvalidTokenError as e:
            print(f" Invalid token: {e}")
            return False
        except Exception as e:
            print(f" Unexpected error: {e}")
            return False


# Instance to use in routes
jwt_bearer = JWTBearer()