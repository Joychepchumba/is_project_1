from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import HTTPException, status

SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )


def create_access_token (data:dict, expires_delta :timedelta = None):
    to_encode=data.copy()
    expire= datetime.utcnow()+(expires_delta or timedelta(minutes=15))
    to_encode.update({"exp":expire})
    return jwt.encode(to_encode,SECRET_KEY,algorithm=ALGORITHM)

def verify_token(token:str,credentials_exception):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_identifier = payload.get("sub")  # This is where email or phone is extracted
        if user_identifier is None:
            raise credentials_exception
        return user_identifier
    except JWTError:
        raise credentials_exception
