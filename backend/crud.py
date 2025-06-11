import os
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Union, Any
from jose import jwt
from dotenv import load_dotenv
import models
import schema
from models import User,  LegalAidProvider ,EmergencyContact
from schema import CreateUser, CreateLegalAid
import base64
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

# Load environment variables from .env file
load_dotenv()

# JWT Configuration from environment variables
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 10080))  # 7 days default
ALGORITHM = "HS256"
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Ensure secret keys are set
if not JWT_SECRET_KEY or not JWT_REFRESH_SECRET_KEY:
    raise ValueError("JWT_SECRET_KEY and JWT_REFRESH_SECRET_KEY must be set in .env file")

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Create directory for storing profile images
UPLOAD_DIR = "uploads/profile_images"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def save_base64_image(base64_string: str, user_id: int, user_type: str) -> str:
    """
    Save base64 encoded image to file system and return the file path
    """
    try:
        # Remove data:image/jpeg;base64, prefix if present
        if "," in base64_string:
            base64_string = base64_string.split(",")[1]
        
        # Decode base64 string
        image_data = base64.b64decode(base64_string)
        
        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{user_type}_{user_id}_{timestamp}_{uuid.uuid4().hex[:8]}.jpg"
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        # Save image to file
        with open(file_path, "wb") as f:
            f.write(image_data)
        
        # Return relative path that can be used as URL
        return f"/uploads/profile_images/{filename}"
        
    except Exception as e:
        print(f"Error saving image: {e}")
        return None
    
def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        user_type: str = payload.get("user_type")

        if user_id is None or user_type is None:
            raise credentials_exception

        return {"sub": user_id, "user_type": user_type}
    except JWTError:
        raise credentials_exception


# Password functions
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)



def create_access_token(user_id: str, user_type: str, role_id: int):
    payload = {
        "sub": str(user_id),  # Convert UUID to string
        "user_type": user_type,
        "role_id": role_id,
        "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=ALGORITHM)




def create_refresh_token(user_id: int):
    expire = datetime.utcnow() + timedelta(days=7)
    payload = {
        "sub": str(user_id),
        "exp": expire
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=ALGORITHM)

# Database query functions
def get_user_by_phone(db: Session, phone_number: str):
    return db.query(User).filter(User.phone_number == phone_number).first()

def create_user(db: Session, user: CreateUser):
    hashed_password = get_password_hash(user.password_hash)
    db_user = User(
        full_name=user.full_name,
        phone_number=user.phone_number,
        email=user.email,
        password_hash=hashed_password,
        role_id=user.role_id,
        profile_image=user.profile_image,
        created_at=datetime.utcnow() 
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Save profile image if provided
    if user.profile_image:
        image_path = save_base64_image(user.profile_image, db_user.id, "user")
        if image_path:
            db_user.profile_image = image_path
            db.commit()
            db.refresh(db_user)

    if user.emergency_contact_name and user.emergency_contact_number:
        emergency_contact = EmergencyContact(
            user_id=db_user.id,
            contact_name=user.emergency_contact_name,
            contact_number=user.emergency_contact_number,
            email_contact=user.emergency_contact_email
        )
        db.add(emergency_contact)
        db.commit()
        db.refresh(emergency_contact)

    return db_user

def create_legal_aid(db: Session, legal_aid: CreateLegalAid):
    hashed_password = get_password_hash(legal_aid.password_hash)
    db_legal_aid = LegalAidProvider(
        full_name=legal_aid.full_name,
        phone_number=legal_aid.phone_number,
        email=legal_aid.email,
        password_hash=hashed_password,
        expertise_area=legal_aid.expertise_area,
        status=legal_aid.status,
        role_id=legal_aid.role_id,
        profile_image=legal_aid.profile_image,
        created_at=datetime.utcnow() 
    )
    db.add(db_legal_aid)
    db.commit()
    db.refresh(db_legal_aid)
    # Save profile image if provided
    if legal_aid.profile_image:
        image_path = save_base64_image(legal_aid.profile_image, db_legal_aid.id, "legal_aid")
        if image_path:
            db_legal_aid.profile_image = image_path
            db.commit()
            db.refresh(db_legal_aid)
    
    return db_legal_aid