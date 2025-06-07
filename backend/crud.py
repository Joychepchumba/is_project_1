import os
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Union, Any
from jose import jwt
from dotenv import load_dotenv
import models
import schema
from models import User,  LegalAidProvider 
from schema import CreateUser, CreateLegalAid 
# Load environment variables from .env file
load_dotenv()

# JWT Configuration from environment variables
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 10080))  # 7 days default
ALGORITHM = "HS256"
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY")

# Ensure secret keys are set
if not JWT_SECRET_KEY or not JWT_REFRESH_SECRET_KEY:
    raise ValueError("JWT_SECRET_KEY and JWT_REFRESH_SECRET_KEY must be set in .env file")

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Password functions
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# JWT Token functions
def create_access_token(user_id: int, user_type: str = "user"):
    expire = datetime.utcnow() + timedelta(minutes=30)
    payload = {
        "sub": str(user_id),         
        "user_type": user_type,      
        "exp": expire                
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
        created_at=datetime.utcnow() 
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
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
        created_at=datetime.utcnow() 
    )
    db.add(db_legal_aid)
    db.commit()
    db.refresh(db_legal_aid)
    return db_legal_aid