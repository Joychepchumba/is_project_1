from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from database import get_db
import crud
import models
import schema
from models import User, LegalAidProvider, UserTokenTable, LegalAidTokenTable
from schema import CreateUser, CreateLegalAid, changepassword, TokenSchema, ShowUser, ShowLegalAid,editprofile
from crud import verify_password, get_password_hash, create_access_token, create_refresh_token,get_current_user
from fastapi import Request
import requests
from auth import jwt_bearer, decodeJWT
import jwt
from dotenv import load_dotenv
import os
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


load_dotenv()

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))
REFRESH_TOKEN_EXPIRE_MINUTES = int(os.getenv("REFRESH_TOKEN_EXPIRE_MINUTES", 60 * 24 * 7))  # 7 days
ALGORITHM = "HS256"
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY")

# Serve uploaded images as static files
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/")
async def root():
    return {"message": "Hello from FastAPI!"}

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
    # Query with explicit role_id selection
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
    role_id = None  # Initialize explicitly

    if user and verify_password(form_data.password, user.password_hash):
        authenticated_user = user
        user_type = "user"
        # Force refresh from database to ensure role_id is loaded
        db.refresh(user)
        role_id = user.role_id
        print(f"USER - ID: {user.id}, role_id: {role_id}")
        
    elif legal_aid and verify_password(form_data.password, legal_aid.password_hash):
        authenticated_user = legal_aid
        user_type = "legal_aid"
        # Force refresh from database to ensure role_id is loaded
        db.refresh(legal_aid)
        role_id = legal_aid.role_id
        print(f"LEGAL_AID - ID: {legal_aid.id}, role_id: {role_id}")

    if not authenticated_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid credentials"
        )

    # Double-check role_id is not None
    if role_id is None:
        print(f"WARNING: role_id is None for user {authenticated_user.id}")
        # Query specifically for role_id
        if user_type == "user":
            role_result = db.query(models.User.role_id).filter(models.User.id == authenticated_user.id).first()
        else:
            role_result = db.query(models.LegalAidProvider.role_id).filter(models.LegalAidProvider.id == authenticated_user.id).first()
        
        role_id = role_result[0] if role_result else None
        print(f"Direct role_id query result: {role_id}")

    access_token = create_access_token(str(authenticated_user.id), user_type, role_id)
    refresh_token = create_refresh_token(str(authenticated_user.id))
    user_id = authenticated_user.id

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
    
    print(f"FINAL RESPONSE - role_id: {role_id}")

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "role_id": role_id,
        
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


@app.post('/editProfile')
def edit_profile(request: editprofile, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    # Get current user info from JWT token
    user_id = current_user["sub"]
    user_type = current_user["user_type"]
    
    # Query based on user type from JWT
    if user_type == "user":
        account = db.query(models.User).filter(models.User.id == user_id).first()
    else:  # legal_aid
        account = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.id == user_id).first()
    
    if not account:
        raise HTTPException(status_code=400, detail="Account not found")

    # Verify old password
    if not verify_password(request.old_password, account.password_hash):
        raise HTTPException(status_code=400, detail="Invalid old password")

    # Update based on user type and role
    if user_type == "user":
        # Update basic user fields
        account.password_hash = get_password_hash(request.new_password)
        account.full_name = request.full_name
        account.email = request.email
        account.phone_number = request.phone_number
        
        # Handle profile image if provided
        if hasattr(request, 'profile_image') and request.profile_image:
            account.profile_image = request.profile_image
        
        # Handle emergency contacts for regular users (role_id 5)
        if account.role_id == 5:
            # Check if emergency contact exists
            emergency_contact = db.query(models.EmergencyContact).filter(
                models.EmergencyContact.user_id == user_id
            ).first()
            
            if emergency_contact:
                # Update existing emergency contact
                emergency_contact.contact_name = request.emergency_contact_name
                emergency_contact.email_contact = request.emergency_contact_email
                emergency_contact.contact_number = request.emergency_contact_number
            else:
                # Create new emergency contact
                new_emergency_contact = models.EmergencyContact(
                    user_id=user_id,
                    contact_name=request.emergency_contact_name,
                    email_contact=request.emergency_contact_email,
                    contact_number=request.emergency_contact_number
                )
                db.add(new_emergency_contact)
    
    elif user_type == "legal_aid":
        # Update legal aid provider fields
        account.password_hash = get_password_hash(request.new_password)
        account.full_name = request.full_name
        account.email = request.email
        account.phone_number = request.phone_number
        
        # Handle expertise area if provided
        if hasattr(request, 'expertise_area') and request.expertise_area:
            account.expertise_area = request.expertise_area
    
    try:
        db.commit()
        db.refresh(account)
        return {"message": "Profile successfully changed"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to update profile")



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

@app.get("/emergency-contacts")
def get_emergency_contacts(token: str = Depends(jwt_bearer), db: Session = Depends(get_db)):
    payload = decodeJWT(token)
    if not payload:
        raise HTTPException(status_code=403, detail="Invalid token")

    user_id = payload.get("sub")
    user_type = payload.get("user_type")
    role_id = payload.get("role_id")

    # Only allow users (not legal aid providers) and only those with role_id == 5
    if user_type != "user" or role_id != 5:
        raise HTTPException(
            status_code=403, 
            detail="Emergency contacts are only available for specific user roles"
        )

    # Get emergency contacts for the user
    emergency_contacts = db.query(models.EmergencyContact).filter(
        models.EmergencyContact.user_id == user_id
    ).all()

    # Format the response
    contacts_response = []
    for contact in emergency_contacts:
        contacts_response.append({
            "id": contact.id,
            "contact_name": contact.contact_name,
            "contact_number": contact.contact_number,
            "email_contact": contact.email_contact
        })

    return contacts_response

@app.get("/profile")
def get_profile(token: str = Depends(jwt_bearer), db: Session = Depends(get_db)):
    print(f"DEBUG: Received token: {token[:50]}...")
    
    payload = decodeJWT(token)
    print(f"DEBUG: Decoded payload: {payload}")
    
    if not payload:
        print("DEBUG: Invalid token - payload is None")
        raise HTTPException(status_code=403, detail="Invalid token")

    user_id = payload.get("sub")
    user_type = payload.get("user_type")
    role_id = payload.get("role_id")
    
    print(f"DEBUG: user_id={user_id} (type: {type(user_id)})")
    print(f"DEBUG: user_type={user_type}")
    print(f"DEBUG: role_id={role_id}")

    if user_type == "user":
        # Try both string and converted types
        print(f"DEBUG: Querying User table with id: {user_id}")
        
        # If your User.id is UUID, you might need to convert
        if isinstance(user_id, str):
            try:
                # If using UUID
                import uuid
                user_uuid = uuid.UUID(user_id)
                user = db.query(models.User).filter(models.User.id == user_uuid).first()
            except:
                # If using string directly  
                user = db.query(models.User).filter(models.User.id == user_id).first()
        else:
            user = db.query(models.User).filter(models.User.id == user_id).first()
            
        print(f"DEBUG: Found user: {user}")
        print(f"DEBUG: User query result - user is None: {user is None}")
        
        if not user:
            # Let's check what users exist
            all_users = db.query(models.User.id, models.User.full_name).limit(5).all()
            print(f"DEBUG: Sample users in database: {all_users}")
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "id": str(user.id),  # Convert to string for consistency
            "name": user.full_name,
            "email": user.email,
            "phone_number": user.phone_number,
            "profile_image": user.profile_image,
            "user_type": user_type,
            "role_id": role_id
        }
    elif user_type == "legal_aid":
        print(f"DEBUG: Querying LegalAidProvider table with id: {user_id}")
        
        if isinstance(user_id, str):
            try:
                import uuid
                user_uuid = uuid.UUID(user_id)
                legal_aid = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.id == user_uuid).first()
            except:
                legal_aid = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.id == user_id).first()
        else:
            legal_aid = db.query(models.LegalAidProvider).filter(models.LegalAidProvider.id == user_id).first()
            
        print(f"DEBUG: Found legal_aid: {legal_aid}")
        
        if not legal_aid:
            all_providers = db.query(models.LegalAidProvider.id, models.LegalAidProvider.full_name).limit(5).all()
            print(f"DEBUG: Sample legal aid providers in database: {all_providers}")
            raise HTTPException(status_code=404, detail="Legal aid provider not found")
        
        return {
            "id": str(legal_aid.id),
            "name": legal_aid.full_name,
            "email": legal_aid.email,
            "phone_number": legal_aid.phone_number,
            "profile_image": getattr(legal_aid, 'profile_image', None),
            "expertise_area": legal_aid.expertise_area,
            "user_type": user_type,
            "role_id": role_id
        }
    else:
        print(f"DEBUG: Unknown user_type: {user_type}")
        raise HTTPException(status_code=400, detail="Invalid user type")
