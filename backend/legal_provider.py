# api/legal_aid_providers.py - Separate router for provider endpoints
from typing import List, Optional
import uuid
import logging
import traceback
from fastapi import APIRouter, Depends, HTTPException, status
from uuid import UUID
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel

from database import get_db
from models import LegalAidProvider, ExpertiseArea

# Correct router for legal aid providers
router = APIRouter(prefix="/api/legal-aid-providers", tags=["legal-aid-providers"])

from datetime import datetime

class LegalAidProviderResponse(BaseModel):
    id: UUID
    full_name: str
    phone_number: str
    email: str
    status: str
    profile_image: Optional[str] = None
    psk_number: str
    about: Optional[str] = None
    expertise_area_ids: Optional[List[str]] = []
    created_at: datetime  # Change this from str to datetime

    class Config:
        from_attributes = True

# Get all verified providers
@router.get("/", response_model=List[LegalAidProviderResponse])
async def get_all_providers(
    skip: int = 0,
    limit: int = 100,
    status_filter: Optional[str] = "verified",
    db: Session = Depends(get_db)
):
    """Get all legal aid providers"""
    try:
        query = db.query(LegalAidProvider).options(
            joinedload(LegalAidProvider.expertise_areas)
        )
        
        if status_filter:
            query = query.filter(LegalAidProvider.status == status_filter)
        
        providers = query.order_by(LegalAidProvider.created_at.desc()).offset(skip).limit(limit).all()
        
        return providers
    except Exception as e:
        logging.error(f"Error fetching providers: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching providers: {str(e)}"
        )

# Get a specific provider by ID
@router.get("/{provider_id}", response_model=LegalAidProviderResponse)
async def get_provider_by_id(provider_id: UUID, db: Session = Depends(get_db)):
    """Get a specific legal aid provider by ID"""
    try:
        provider = db.query(LegalAidProvider).options(
            joinedload(LegalAidProvider.expertise_areas)
        ).filter(LegalAidProvider.id == provider_id).first()
        
        if not provider:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Legal aid provider with ID {provider_id} not found"
            )
        
        return provider
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error fetching provider: {str(e)}")
        logging.error(f"Provider ID: {provider_id}")
        logging.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching provider: {str(e)}"
        )

# Get providers by expertise area
@router.get("/expertise/{expertise_id}")
async def get_providers_by_expertise(
    expertise_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get providers by expertise area"""
    try:
        providers = db.query(LegalAidProvider).options(
            joinedload(LegalAidProvider.expertise_areas)
        ).join(
            LegalAidProvider.expertise_areas
        ).filter(
            ExpertiseArea.id == expertise_id,
            LegalAidProvider.status == "verified"
        ).order_by(LegalAidProvider.created_at.desc()).offset(skip).limit(limit).all()
        
        return providers
    except Exception as e:
        logging.error(f"Error fetching providers by expertise: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching providers by expertise: {str(e)}"
        )

# Search providers
@router.get("/search/")
async def search_providers(
    q: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Search providers by name or expertise"""
    try:
        providers = db.query(LegalAidProvider).options(
            joinedload(LegalAidProvider.expertise_areas)
        ).filter(
            LegalAidProvider.status == "verified"
        ).filter(
            LegalAidProvider.full_name.ilike(f"%{q}%")
        ).order_by(LegalAidProvider.created_at.desc()).offset(skip).limit(limit).all()
        
        return providers
    except Exception as e:
        logging.error(f"Error searching providers: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error searching providers: {str(e)}"
        )