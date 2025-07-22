from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_
from typing import List, Optional
from uuid import UUID
import base64
import uuid
import os
from datetime import datetime
import mimetypes

from schema import Base64ImageUpload, CreateLegalTipRequest, UpdateLegalTipRequest
from crud import get_current_user
from database import get_db
from models import LegalTip, LegalAidProvider, TipStatus
from schema import (
    CreateLegalTip, 
    UpdateLegalTip, 
    ShowLegalTip, 
    LegalTipWithProvider,
    LegalTipBase
)

router = APIRouter(prefix="/api/v1/legal-tips", tags=["Legal Tips"])
security = HTTPBearer()

# Image upload configuration
UPLOAD_DIR = "uploads/legal_tips"
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}

# Ensure upload directory exists
os.makedirs(UPLOAD_DIR, exist_ok=True)

def allowed_file(filename: str) -> bool:
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_base64_image(base64_string: str, filename_prefix: str = None) -> str:
    """Save base64 encoded image and return the file path"""
    try:
        # Remove data URL prefix if present
        if base64_string.startswith('data:image/'):
            header, base64_string = base64_string.split(',', 1)
            # Extract mime type
            mime_type = header.split(';')[0].split(':')[1]
            extension = mime_type.split('/')[1]
        else:
            extension = 'png'  # default
        
        # Decode base64
        image_data = base64.b64decode(base64_string)
        
        # Generate unique filename
        if filename_prefix:
            filename = f"{filename_prefix}_{uuid.uuid4()}.{extension}"
        else:
            filename = f"{uuid.uuid4()}.{extension}"
        
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        # Save file
        with open(file_path, 'wb') as f:
            f.write(image_data)
        
        # Return relative path for storing in database
        return f"/uploads/legal_tips/{filename}"
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error processing image: {str(e)}"
        )

@router.post("/", response_model=ShowLegalTip)
async def create_legal_tip(
    tip_data: CreateLegalTip,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new legal tip"""
    
    # Verify that the legal aid provider exists and belongs to current user
    provider = db.query(LegalAidProvider).filter(
        LegalAidProvider.id == tip_data.legal_aid_provider_id
    ).first()
    
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal aid provider not found"
        )
    
    # Handle image upload if provided
    image_url = None
    if tip_data.image_url and tip_data.image_url.startswith('data:image/'):
        image_url = save_base64_image(tip_data.image_url, "tip")
    elif tip_data.image_url:
        image_url = tip_data.image_url  # If it's already a URL
    
    # Create the tip
    db_tip = LegalTip(
        title=tip_data.title,
        description=tip_data.description,
        image_url=image_url,
        status=tip_data.status,
        legal_aid_provider_id=tip_data.legal_aid_provider_id,
        published_at=datetime.utcnow() if tip_data.status == TipStatus.published else None
    )
    
    db.add(db_tip)
    db.commit()
    db.refresh(db_tip)
    
    return db_tip

@router.get("/", response_model=List[LegalTipWithProvider])
async def get_legal_tips(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[TipStatus] = None,
    provider_id: Optional[UUID] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get all legal tips with optional filters"""
    
    # FIXED: Use joinedload to eagerly load the legal_aid_provider relationship
    query = db.query(LegalTip).options(
        joinedload(LegalTip.legal_aid_provider)
    )
    
    # Apply filters
    if status_filter:
        query = query.filter(LegalTip.status == status_filter)
    
    if provider_id:
        query = query.filter(LegalTip.legal_aid_provider_id == provider_id)
    
    if search:
        query = query.filter(
            or_(
                LegalTip.title.ilike(f"%{search}%"),
                LegalTip.description.ilike(f"%{search}%")
            )
        )
    
    # Order by created_at desc and apply pagination
    tips = query.order_by(LegalTip.created_at.desc()).offset(skip).limit(limit).all()
    
    return tips

@router.get("/{tip_id}", response_model=LegalTipWithProvider)
async def get_legal_tip(
    tip_id: UUID,
    db: Session = Depends(get_db)
):
    """Get a specific legal tip"""
    
    # FIXED: Use joinedload to eagerly load the legal_aid_provider relationship
    tip = db.query(LegalTip).options(
        joinedload(LegalTip.legal_aid_provider)
    ).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal tip not found"
        )
    
    return tip

@router.put("/{tip_id}", response_model=ShowLegalTip)
async def update_legal_tip(
    tip_id: UUID,
    tip_data: UpdateLegalTip,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a legal tip"""
    
    tip = db.query(LegalTip).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal tip not found"
        )
    
    # Update fields
    update_data = tip_data.dict(exclude_unset=True)
    
    # Handle image update
    if 'image_url' in update_data:
        if update_data['image_url'] and update_data['image_url'].startswith('data:image/'):
            # Delete old image if exists
            if tip.image_url and tip.image_url.startswith('/uploads/'):
                old_file_path = f".{tip.image_url}"
                if os.path.exists(old_file_path):
                    os.remove(old_file_path)
            
            # Save new image
            update_data['image_url'] = save_base64_image(update_data['image_url'], "tip")
        elif update_data['image_url'] is None:
            # Remove image
            if tip.image_url and tip.image_url.startswith('/uploads/'):
                old_file_path = f".{tip.image_url}"
                if os.path.exists(old_file_path):
                    os.remove(old_file_path)
    
    # Handle status change to published
    if 'status' in update_data and update_data['status'] == TipStatus.published:
        if tip.status != TipStatus.published:
            update_data['published_at'] = datetime.utcnow()
    
    # Update the tip
    for field, value in update_data.items():
        setattr(tip, field, value)
    
    db.commit()
    db.refresh(tip)
    
    return tip

@router.patch("/{tip_id}/status", response_model=ShowLegalTip)
async def update_tip_status(
    tip_id: UUID,
    new_status: TipStatus,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update tip status (publish, archive, etc.)"""
    
    tip = db.query(LegalTip).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal tip not found"
        )
    
    # Update status
    old_status = tip.status
    tip.status = new_status
    
    # Set published_at if publishing for the first time
    if new_status == TipStatus.published and old_status != TipStatus.published:
        tip.published_at = datetime.utcnow()
    
    db.commit()
    db.refresh(tip)
    
    return tip

@router.delete("/{tip_id}")
async def delete_legal_tip(
    tip_id: UUID,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a legal tip"""
    
    tip = db.query(LegalTip).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal tip not found"
        )
    
    # Delete associated image file
    if tip.image_url and tip.image_url.startswith('/uploads/'):
        file_path = f".{tip.image_url}"
        if os.path.exists(file_path):
            os.remove(file_path)
    
    db.delete(tip)
    db.commit()
    
    return {"message": "Legal tip deleted successfully"}

@router.post("/upload-image")
async def upload_image(
    file: UploadFile = File(...),
    current_user = Depends(get_current_user)
):
    """Upload image file and return URL"""
    
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No file selected"
        )
    
    if not allowed_file(file.filename):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Allowed types: png, jpg, jpeg, gif, webp"
        )
    
    # Check file size
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File too large. Maximum size is 10MB"
        )
    
    # Generate unique filename
    extension = file.filename.rsplit('.', 1)[1].lower()
    filename = f"{uuid.uuid4()}.{extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    # Save file
    with open(file_path, 'wb') as f:
        f.write(contents)
    
    return {"image_url": f"/uploads/legal_tips/{filename}"}

@router.get("/provider/{provider_id}", response_model=List[ShowLegalTip])
async def get_tips_by_provider(
    provider_id: UUID,
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[TipStatus] = None,
    db: Session = Depends(get_db)
):
    """Get all tips for a specific legal aid provider"""
    
    query = db.query(LegalTip).filter(LegalTip.legal_aid_provider_id == provider_id)
    
    if status_filter:
        query = query.filter(LegalTip.status == status_filter)
    
    tips = query.order_by(LegalTip.created_at.desc()).offset(skip).limit(limit).all()
    return tips

@router.get("/published/recent", response_model=List[LegalTipWithProvider])
async def get_recent_published_tips(
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """Get recently published tips"""
    
    # FIXED: Use joinedload to eagerly load the legal_aid_provider relationship
    tips = db.query(LegalTip).options(
        joinedload(LegalTip.legal_aid_provider)
    ).filter(
        LegalTip.status == TipStatus.published
    ).order_by(LegalTip.published_at.desc()).limit(limit).all()
    
    return tips

@router.post("/create", response_model=ShowLegalTip)
async def create_legal_tip_with_base64(
    request: CreateLegalTipRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new legal tip with base64 image handling"""
    
    # Verify provider exists
    provider = db.query(LegalAidProvider).filter(
        LegalAidProvider.id == request.legal_aid_provider_id
    ).first()
    
    if not provider:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal aid provider not found"
        )
    
    # Handle base64 image
    image_url = None
    if request.image_base64:
        try:
            image_url = save_base64_image(request.image_base64, "tip")
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Error processing image: {str(e)}"
            )
    
    # Create tip
    db_tip = LegalTip(
        title=request.title,
        description=request.description,
        image_url=image_url,
        status=request.status,
        legal_aid_provider_id=request.legal_aid_provider_id,
        published_at=datetime.utcnow() if request.status == TipStatus.published else None
    )
    
    db.add(db_tip)
    db.commit()
    db.refresh(db_tip)
    
    return db_tip

@router.put("/{tip_id}/update", response_model=ShowLegalTip)
async def update_legal_tip_with_base64(
    tip_id: UUID,
    request: UpdateLegalTipRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update legal tip with base64 image handling"""
    
    tip = db.query(LegalTip).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Legal tip not found"
        )
    
    # Update fields
    if request.title is not None:
        tip.title = request.title
    
    if request.description is not None:
        tip.description = request.description
    
    if request.image_base64 is not None:
        # Delete old image if exists
        if tip.image_url and tip.image_url.startswith('/uploads/'):
            old_file_path = f".{tip.image_url}"
            if os.path.exists(old_file_path):
                os.remove(old_file_path)
        
        # Save new image
        if request.image_base64:  # If not empty string
            try:
                tip.image_url = save_base64_image(request.image_base64, "tip")
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Error processing image: {str(e)}"
                )
        else:
            tip.image_url = None
    
    if request.status is not None:
        old_status = tip.status
        tip.status = request.status
        
        # Set published_at if publishing for the first time
        if request.status == TipStatus.published and old_status != TipStatus.published:
            tip.published_at = datetime.utcnow()
    
    db.commit()
    db.refresh(tip)
    
    return tip

@router.post("/upload-base64-image")
async def upload_base64_image(
    image_data: Base64ImageUpload,
    current_user = Depends(get_current_user)
):
    """Upload base64 encoded image and return URL"""
    
    try:
        image_url = save_base64_image(
            image_data.image_data, 
            image_data.filename or "tip"
        )
        return {"image_url": image_url}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error processing image: {str(e)}"
        )
    
@router.get("/debug/{tip_id}")
async def debug_tip(tip_id: UUID, db: Session = Depends(get_db)):
    tip = db.query(LegalTip).options(
        joinedload(LegalTip.legal_aid_provider)
    ).filter(LegalTip.id == tip_id).first()
    
    if not tip:
        raise HTTPException(status_code=404, detail="Tip not found")
    
    # Return the raw data to see the structure
    return {
        "tip_id": str(tip.id),
        "provider_id": str(tip.legal_aid_provider_id),
        "provider_data": {
            "id": str(tip.legal_aid_provider.id) if tip.legal_aid_provider else None,
            "full_name": tip.legal_aid_provider.full_name if tip.legal_aid_provider else None,
            "phone_number": tip.legal_aid_provider.phone_number if tip.legal_aid_provider else None,
            "email": tip.legal_aid_provider.email if tip.legal_aid_provider else None,
            "psk_number": tip.legal_aid_provider.psk_number if tip.legal_aid_provider else None,
            "status": tip.legal_aid_provider.status if tip.legal_aid_provider else None,
        }
    }