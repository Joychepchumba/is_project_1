from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from database import get_db
import crud
import models
import schema
from models import User, LegalAidProvider, UserTokenTable, LegalAidTokenTable
from schema import CreateUser, CreateLegalAid, changepassword, TokenSchema, ShowUser, ShowLegalAid
from crud import verify_password, get_password_hash, create_access_token, create_refresh_token
from fastapi import Request
import requests
from auth import jwt_bearer, decodeJWT
import jwt
from dotenv import load_dotenv
import os

app = FastAPI()
load_dotenv()

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 60 * 24 * 7))  # 7 days
ALGORITHM = "HS256"
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY")

@app.post("/register/user", response_model=ShowUser)
def register_user(user: CreateUser, db: Session = Depends(get_db)):
    existing_user = db.query(models.User).filter(
        (models.User.phone_number == user.phone_number) |
        (models.User.email == user.email)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists"
        )
    created_user = crud.create_user(db, user)
    return created_user

@app.post("/register/legal_aid_provider", response_model=ShowLegalAid)
def register_legal_aid(legal_aid: CreateLegalAid, db: Session = Depends(get_db)):
    existing_legal_aid_provider = db.query(models.LegalAidProvider).filter(
        (models.LegalAidProvider.phone_number == legal_aid.phone_number) |
        (models.LegalAidProvider.email == legal_aid.email)
    ).first()
    if existing_legal_aid_provider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account exists"
        )
    created_legal_aid = crud.create_legal_aid(db, legal_aid)
    return created_legal_aid

@app.post("/login", response_model=TokenSchema)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        (models.User.email == form_data.username) |
        (models.User.phone_number == form_data.username)
    ).first()

    legal_aid = db.query(models.LegalAidProvider).filter(
        (models.LegalAidProvider.email == form_data.username) |
        (models.LegalAidProvider.phone_number == form_data.username)
    ).first()

    authenticated_user = None
    user_type = None

    if user and verify_password(form_data.password, user.password_hash):
        authenticated_user = user
        user_type = "user"
    elif legal_aid and verify_password(form_data.password, legal_aid.password_hash):
        authenticated_user = legal_aid
        user_type = "legal_aid"

    if not authenticated_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid credentials"
        )

    access_token = create_access_token(authenticated_user.id, user_type)
    refresh_token = create_refresh_token(authenticated_user.id)

    if user_type == "user":
        token_db = UserTokenTable(
            user_id=authenticated_user.id,
            access_token=access_token,
            refresh_token=refresh_token,
            status=True
        )
    else:  # legal_aid
        token_db = LegalAidTokenTable(
            provider_id=authenticated_user.id,
            access_token=access_token,
            refresh_token=refresh_token,
            status=True
        )

    db.add(token_db)
    db.commit()
    db.refresh(token_db)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token
    }

@app.post("/google/login", response_model=TokenSchema)
def google_login(token: str, db: Session = Depends(get_db)):
    response = requests.get(f'https://oauth2.googleapis.com/tokeninfo?id_token={token}')
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Google credentials")

    user_info = response.json()
    email = user_info['email']

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        user = models.User(
            email=email,
            full_name=user_info.get('name', ''),
            password_hash="",  # Google auth user has no password
            role_id=2  # example role id for normal user
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    access_token = create_access_token(user.id, "user")
    refresh_token = create_refresh_token(user.id)

    token_db = UserTokenTable(
        user_id=user.id,
        access_token=access_token,
        refresh_token=refresh_token,
        status=True
    )
    db.add(token_db)
    db.commit()
    db.refresh(token_db)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token
    }

@app.get("/profile")
def get_profile(token: str = Depends(jwt_bearer), db: Session = Depends(get_db)):
    payload = decodeJWT(token)
    if not payload:
        raise HTTPException(status_code=403, detail="Invalid token")

    user_id = payload.get("sub")
    user_type = payload.get("user_type")

    if user_type == "user":
        user = db.query(models.User).filter(models.User.id == user_id).first()
    else:
        user = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "name": user.full_name,
        "email": user.email,
        "user_type": user_type
    }

@app.get('/getusers', response_model=list[ShowUser])
def getusers(db: Session = Depends(get_db), token: str = Depends(jwt_bearer)):
    users = db.query(models.User).all()
    return users

@app.post('/changePassword')
def change_password(request: changepassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == request.email).first()
    legal_aid = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.email == request.email).first()

    account = user or legal_aid
    if not account:
        raise HTTPException(status_code=400, detail="Account not found")

    if not verify_password(request.old_password, account.password_hash):
        raise HTTPException(status_code=400, detail="Invalid old password")

    account.password_hash = get_password_hash(request.new_password)
    db.commit()

    return {"message": "Password changed successfully"}

@app.post('/logout')
def logout(token: str = Depends(jwt_bearer), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        user_type = payload.get("user_type")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    if user_type == "user":
        token_record = db.query(UserTokenTable).filter(
            UserTokenTable.user_id == user_id,
            UserTokenTable.access_token == token
        ).first()
    elif user_type == "legal_aid":
        token_record = db.query(LegalAidTokenTable).filter(
            LegalAidTokenTable.provider_id == user_id,
            LegalAidTokenTable.access_token == token
        ).first()
    else:
        raise HTTPException(status_code=400, detail="Unknown user type")

    if not token_record:
        raise HTTPException(status_code=404, detail="Token not found")

    token_record.status = False
    db.commit()

    return {"message": "Logged out successfully"}
