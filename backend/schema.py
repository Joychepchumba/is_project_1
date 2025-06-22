from pydantic import BaseModel, EmailStr, UUID4
from typing import Optional, List
from datetime import datetime

'''
So this ka code is like to sort of set the design ya the processes 
So like kama login will be done using phone no and password
alafu kama ku update you can  update information like phone no etc but huwezi update ids , created at you get

'''
# ===============================
# User Schemas
# ===============================

class UserBase(BaseModel):
    full_name: str
    phone_number: str
    email: EmailStr
    role_id: int
    profile_image: Optional[str] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_number: Optional[str] = None
    emergency_contact_email: Optional[EmailStr] = None

class CreateUser(UserBase):
    password_hash: Optional[str] = None
    role_id: int
    google_oauth: Optional[bool] = False

class LoginGoogleUser(BaseModel):
    email: EmailStr

class LoginUser(BaseModel):
    identifier: str
    password_hash: str

class UpdateUser(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    password_hash: Optional[str] = None

class ShowUser(UserBase):
    id: UUID4

    model_config = {
        "from_attributes": True
    }

class TokenSchema(BaseModel):
    access_token: str
    refresh_token: str

class changepassword(BaseModel):
    email: str
    old_password: str
    new_password: str

class TokenCreate(BaseModel):
    user_id: str
    access_token: str
    refresh_token: str
    status: bool
    created_date: datetime

# ===============================
# Expertise Area Schemas
# ===============================

class ExpertiseAreaBase(BaseModel):
    name: str

class ExpertiseAreaCreate(ExpertiseAreaBase):
    pass

class ExpertiseAreaOut(ExpertiseAreaBase):
    id: int

    model_config = {
        "from_attributes": True
    }

# ===============================
# Legal Aid Provider Schemas
# ===============================

class LegalAidProviderBase(BaseModel):
    full_name: str
    phone_number: str
    email: EmailStr
    status: str
    profile_image: Optional[str] = None
    psk_number: str

class CreateLegalAid(LegalAidProviderBase):
    password_hash: Optional[str] = None
    role_id: int
    google_oauth: Optional[bool] = False
    expertise_area_ids: List[int]

class LoginLglAidGoogleUser(BaseModel):
    email: EmailStr

class LoginLegalAid(BaseModel):
    identifier: str
    password_hash: str

class UpdateLegalAid(BaseModel):
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[EmailStr] = None
    password_hash: Optional[str] = None
    status: Optional[str] = None
    profile_image: Optional[str] = None
    psk_number: Optional[str] = None
    expertise_area_ids: Optional[List[int]] = None

class ShowLegalAid(LegalAidProviderBase):
    id: UUID4
    expertise_areas: List[ExpertiseAreaOut]
    created_at: datetime

    model_config = {
        "from_attributes": True
    }

class editprofile(BaseModel):
    old_password: str
    new_password: str
    full_name: str
    email: str
    phone_number: str
    profile_image: Optional[str] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_email: Optional[str] = None
    emergency_contact_number: Optional[str] = None

    expertise_area: Optional[str] = None

# ===============================
# Emergency Contact Schemas
# ===============================

class EmergencyContactBase(BaseModel):
    contact_name: str
    contact_number: str
    email_contact: Optional[EmailStr] = None

class CreateEmergencyContact(EmergencyContactBase):
    user_id: UUID4

class UpdateEmergencyContact(BaseModel):
    contact_name: Optional[str] = None
    contact_number: Optional[str] = None
    email_contact: Optional[EmailStr] = None

class ShowEmergencyContact(EmergencyContactBase):
    id: int

    model_config = {
        "from_attributes": True
    }

# ===============================
# Panic Info Schemas
# ===============================

class PanicInfoBase(BaseModel):
    longitude: float
    latitude: float
    status: Optional[str] = "Pending"
    emergency_contact_notified: Optional[bool] = False
    hotline_notified: Optional[bool] = False
    additional_notes: Optional[str] = None

class CreatePanicInfo(PanicInfoBase):
    user_id: UUID4

class UpdatePanicInfo(BaseModel):
    status: Optional[str] = None
    emergency_contact_notified: Optional[bool] = None
    hotline_notified: Optional[bool] = None
    additional_notes: Optional[str] = None

class ShowPanicInfo(PanicInfoBase):
    id: int

    model_config = {
        "from_attributes": True
    }

# ===============================
# Notification Schemas
# ===============================

class NotificationBase(BaseModel):
    receiver_contact: str
    message: str
    status: str

class CreateNotification(NotificationBase):
    panic_info_id: int

class ShowNotification(NotificationBase):
    id: int

    model_config = {
        "from_attributes": True
    }

# ===============================
# Role Schemas
# ===============================

class Role(BaseModel):
    id: int
    name: str

    model_config = {
        "from_attributes": True
    }

# ===============================
# User Legal Match Schemas
# ===============================

class UserLegalMatchBase(BaseModel):
    user_id: UUID4
    legal_aid_id: UUID4
    status: str

class ShowUserLegalMatch(UserLegalMatchBase):
    id: int

    model_config = {
        "from_attributes": True
    }

# ===============================
# Other Schemas
# ===============================

class Activity(BaseModel):
    id: int
    name: str

    model_config = {
        "from_attributes": True
    }

class RealTimeGPSLogBase(BaseModel):
    user_id: UUID4
    activity_id: int
    latitude: float
    longitude: float
    recorded_at: Optional[datetime] = None

class RealTimeGPSLogCreate(RealTimeGPSLogBase):
    pass

class RealTimeGPSLogShow(RealTimeGPSLogBase):
    id: int

    model_config = {
        "from_attributes": True
    }

class SafetyTipBase(BaseModel):
    title: str
    content: str
    submitted_by: UUID4
    submitted_by_role: str
    status: str

class SafetyTipShow(SafetyTipBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class DangerZoneBase(BaseModel):
    location_name: str
    latitude: float
    longitude: float
    description: Optional[str] = None
    reported_count: Optional[int] = 0

class DangerZoneCreate(DangerZoneBase):
    pass

class DangerZoneShow(DangerZoneBase):
    id: int

    model_config = {
        "from_attributes": True
    }

class PoliceLocationBase(BaseModel):
    name: str
    latitude: float
    longitude: float
    contact_number: str

class PoliceLocationCreate(PoliceLocationBase):
    pass

class PoliceLocationShow(PoliceLocationBase):
    id: int

    model_config = {
        "from_attributes": True
    }

class PreviousFemicideDataBase(BaseModel):
    medium: str
    county: str
    text: str
    date: datetime
    type_of_murder: str
    victim_age: int
    date_of_murder: datetime
    location: str
    suspect_relationship: str
    type_of_femicide: str
    murder_scene: str
    killing_mode: str
    circumstances: str
    status_on_arrest: str
    court_date: Optional[datetime] = None
    verdict_date: Optional[datetime] = None
    verdict: str
    sentence_years: int
    days_to_verdict: int

class PreviousFemicideDataCreate(PreviousFemicideDataBase):
    pass

class PreviousFemicideDataShow(PreviousFemicideDataBase):
    id: int

    model_config = {
        "from_attributes": True
    }