from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from fastapi.middleware.cors import CORSMiddleware

# Your actual Supabase credentials
SUPABASE_URL = "https://ngfpaioekpicyvocxsbn.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nZnBhaW9la3BpY3l2b2N4c2JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyNDA1MTgsImV4cCI6MjA2NDgxNjUxOH0.PcSVIRhmbVRN2vPG4yWfqjDsyP_tw_V3oBtL8UZot0I"  # Replace with your real key
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI()

# Allow all frontend origins (good for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

# Pydantic model for uploading safety tips
class SafetyTip(BaseModel):
    title: str
    content: str
    category: str
    submitted_by: str = "anonymous"         # optional fallback
    submitted_by_role: str = "user"         # optional fallback
    status: str = "pending"

@app.get("/get_tips/")
def get_tips():
    try:
        response = supabase.table("safety_tips").select("*").order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/upload_tip/")
def upload_tip(tip: SafetyTip):
    try:
        supabase.table("safety_tips").insert(tip.dict()).execute()
        return {"message": "Tip uploaded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))