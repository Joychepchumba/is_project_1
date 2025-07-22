# api/legal_requests.py - Updated API Routes with Provider Information
from typing import List
import uuid
import logging
import traceback
from fastapi import APIRouter, Depends, HTTPException, status
from uuid import UUID
from typing import List
from sqlalchemy.orm import Session, joinedload
from pydantic import BaseModel
from enum import Enum

from database import get_db
from models import LegalAidRequest, User, LegalAidProvider

router = APIRouter(prefix="/api/legal-aid-requests", tags=["legal-requests"])

class RequestStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    completed = "completed"

class LegalAidRequestUpdate(BaseModel):
    status: RequestStatus

class LegalAidRequestCreate(BaseModel):
    user_id: uuid.UUID
    legal_aid_provider_id: uuid.UUID
    title: str
    description: str

# Get pending requests for a provider (with user info)
@router.get("/provider/{provider_id}/pending")
async def get_pending_requests_for_provider(
    provider_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Get pending legal aid requests for a provider"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.legal_aid_provider_id == provider_id,
            LegalAidRequest.status == "pending"
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching pending requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching pending requests: {str(e)}"
        )

# Get processed requests for a provider (with user info)
@router.get("/provider/{provider_id}/processed")
async def get_processed_requests_for_provider(
    provider_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Get processed legal aid requests for a provider"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.legal_aid_provider_id == provider_id,
            LegalAidRequest.status.in_(["accepted", "declined", "completed"])
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching processed requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching processed requests: {str(e)}"
        )

# Update request status (returns request with both user and provider info)
@router.patch("/{request_id}")
async def update_request_status(
    request_id: int,
    status_update: LegalAidRequestUpdate,
    db: Session = Depends(get_db)
):
    """Update the status of a legal aid request"""
    try:
        logging.info(f"Attempting to update request {request_id} to status {status_update.status}")
        
        request = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.id == request_id
        ).first()
        
        if not request:
            logging.error(f"Legal aid request with ID {request_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Legal aid request with ID {request_id} not found"
            )
        
        # Validate status transition
        valid_statuses = ["pending", "accepted", "declined", "completed"]
        if status_update.status.value not in valid_statuses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status: {status_update.status.value}"
            )
        
        # Update status
        old_status = request.status
        request.status = status_update.status.value
        db.commit()
        db.refresh(request)
        
        logging.info(f"Successfully updated request {request_id} status from {old_status} to {status_update.status.value}")
        
        return request
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logging.error(f"Error updating request status: {str(e)}")
        logging.error(f"Request ID: {request_id}, Status: {status_update.status}")
        logging.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating request status: {str(e)}"
        )

# Create a new legal aid request (returns request with provider info)
@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_legal_aid_request(
    request_data: LegalAidRequestCreate,
    db: Session = Depends(get_db)
):
    """Create a new legal aid request"""
    try:
        # Verify that the user exists
        user = db.query(User).filter(User.id == request_data.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Verify that the legal aid provider exists and is active
        provider = db.query(LegalAidProvider).filter(
            LegalAidProvider.id == request_data.legal_aid_provider_id,
            LegalAidProvider.status == "verified"
        ).first()
        if not provider:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Legal aid provider not found or inactive"
            )
        
        # Create the request
        new_request = LegalAidRequest(
            user_id=request_data.user_id,
            legal_aid_provider_id=request_data.legal_aid_provider_id,
            title=request_data.title,
            description=request_data.description,
            status="pending"
        )
        
        db.add(new_request)
        db.commit()
        db.refresh(new_request)
        
        # Load both user and provider data for the response
        new_request_with_relations = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(LegalAidRequest.id == new_request.id).first()
        
        return new_request_with_relations
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating legal aid request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating legal aid request: {str(e)}"
        )

# Get all requests for a user (with provider info)
@router.get("/user/{user_id}")
async def get_user_legal_aid_requests(user_id: UUID, db: Session = Depends(get_db)):
    """Get all legal aid requests for a specific user"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.user_id == user_id
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching user requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching user requests: {str(e)}"
        )

# Get a specific request by ID (with both user and provider info)
@router.get("/{request_id}")
async def get_request_by_id(request_id: int, db: Session = Depends(get_db)):
    """Get a specific legal aid request by ID"""
    try:
        request = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(LegalAidRequest.id == request_id).first()
        
        if not request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Legal aid request with ID {request_id} not found"
            )
        
        return request
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error fetching request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching request: {str(e)}"
        )

# Debug endpoint to check request details
@router.get("/debug/{request_id}")
async def debug_request(request_id: int, db: Session = Depends(get_db)):
    """Debug endpoint to check request details"""
    try:
        logging.info(f"Debug: Looking for request with ID: {request_id}")
        
        request = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(LegalAidRequest.id == request_id).first()
        
        if request:
            return {
                "request_id": request_id,
                "found": True,
                "request_details": {
                    "id": request.id,
                    "user_id": request.user_id,
                    "legal_aid_provider_id": request.legal_aid_provider_id,
                    "title": request.title,
                    "status": request.status,
                    "created_at": request.created_at,
                    "user_name": request.user.name if request.user else None,
                    "provider_name": request.legal_aid_provider.name if request.legal_aid_provider else None
                }
            }
        else:
            # Get all requests to see what IDs exist
            all_requests = db.query(LegalAidRequest).limit(10).all()
            sample_ids = [req.id for req in all_requests]
            
            return {
                "request_id": request_id,
                "found": False,
                "sample_existing_ids": sample_ids[:5],
                "total_requests": len(all_requests)
            }
        
    except Exception as e:
        logging.error(f"Error in debug endpoint: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in debug endpoint: {str(e)}"
        )
# Add these endpoints to your legal_requests.py file

# Get accepted requests for a provider (with user info)
@router.get("/provider/{provider_id}/accepted")
async def get_accepted_requests_for_provider(
    provider_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Get accepted legal aid requests for a provider"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.legal_aid_provider_id == provider_id,
            LegalAidRequest.status == "accepted"
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching accepted requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching accepted requests: {str(e)}"
        )
# Get declined requests for a provider (with user info)
@router.get("/provider/{provider_id}/declined")
async def get_declined_requests_for_provider(
    provider_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Get declined legal aid requests for a provider"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.legal_aid_provider_id == provider_id,
            LegalAidRequest.status == "declined"
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching declined requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching declined requests: {str(e)}"
        )

# Get completed requests for a provider (with user info)
@router.get("/provider/{provider_id}/completed")
async def get_completed_requests_for_provider(
    provider_id: uuid.UUID,
    db: Session = Depends(get_db)
):
    """Get completed legal aid requests for a provider"""
    try:
        requests = db.query(LegalAidRequest).options(
            joinedload(LegalAidRequest.user),
            joinedload(LegalAidRequest.legal_aid_provider)
        ).filter(
            LegalAidRequest.legal_aid_provider_id == provider_id,
            LegalAidRequest.status == "completed"
        ).order_by(LegalAidRequest.created_at.desc()).all()
        
        return requests
    except Exception as e:
        logging.error(f"Error fetching completed requests: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching completed requests: {str(e)}"
        )