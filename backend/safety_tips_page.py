from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = "https://ngfpaioekpicyvocxsbn.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nZnBhaW9la3BpY3l2b2N4c2JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDA1MTgsImV4cCI6MjA2NDgxNjUxOH0.PcSVIRhmbVRN2vPG4yWfqjDsyP_tw_V3oBtL8UZot0I"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Router without prefix
router = APIRouter(tags=["Safety Tips"])

# Pydantic model
class SafetyTip(BaseModel):
    title: str
    content: str
    category: str
    submitted_by: str = "anonymous"
    submitted_by_role: str = "user"
    status: str = "pending"

# GET route to fetch all safety tips
@router.get("/get_tips")
def get_tips():
    try:
        response = supabase.table("safety_tips").select("*").order("created_at", desc=True).execute()
        if response.data:
            return response.data
        raise HTTPException(status_code=404, detail="No safety tips found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving tips: {str(e)}")

# POST route to upload a safety tip
@router.post("/upload_tip")
def upload_tip(tip: SafetyTip):
    try:
        if not tip.title or not tip.content or not tip.category:
            raise HTTPException(status_code=400, detail="Title, content, and category are required")

        supabase.table("safety_tips").insert(tip.dict()).execute()
        return {"message": "Tip uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading tip: {str(e)}")
