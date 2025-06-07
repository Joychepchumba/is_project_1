from database import Base
from sqlalchemy import (
    Column, String, Integer, TIMESTAMP, ForeignKey, Text, Boolean, DateTime,
    DECIMAL, text
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
import datetime

class Role(Base):
    __tablename__ = "roles"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)

    users = relationship("User", back_populates="role")
    legal_providers = relationship("LegalAidProvider", back_populates="role")


class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(255))
    phone_number = Column(String(20), unique=True)
    email = Column(String(255), unique=True)
    password_hash = Column(Text)
    role_id = Column(Integer, ForeignKey("roles.id"))
    created_at = Column(TIMESTAMP, server_default=text("now()"))

    role = relationship("Role", back_populates="users")
    safety_tips = relationship("SafetyTip", back_populates="submitted_by_user")
    emergency_contacts = relationship("EmergencyContact", back_populates="user")
    panic_info = relationship("PanicInfo", back_populates="user")


class LegalAidProvider(Base):
    __tablename__ = "legal_aid_providers"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(255))
    phone_number = Column(String(20), unique=True)
    email = Column(String(255), unique=True)
    password_hash = Column(Text)
    expertise_area = Column(String(255))
    status = Column(String(50))
    created_at = Column(TIMESTAMP, server_default=text("now()"))
    role_id = Column(Integer, ForeignKey("roles.id"))

    role = relationship("Role", back_populates="legal_providers")
    safety_tips = relationship("SafetyTip", back_populates="submitted_by_legal")


class SafetyTip(Base):
    __tablename__ = "safety_tips"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255))
    content = Column(Text)
    submitted_by_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    submitted_by_legal_id = Column(UUID(as_uuid=True), ForeignKey("legal_aid_providers.id"), nullable=True)
    created_at = Column(TIMESTAMP, server_default=text("now()"))
    status = Column(String(50))

    submitted_by_user = relationship("User", back_populates="safety_tips")
    submitted_by_legal = relationship("LegalAidProvider", back_populates="safety_tips")


class UserLegalMatch(Base):
    __tablename__ = "user_legal_matches"
    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    legal_aid_id = Column(UUID(as_uuid=True), ForeignKey("legal_aid_providers.id"))
    matched_at = Column(TIMESTAMP, server_default=text("now()"))
    status = Column(String(50))


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"
    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    contact_name = Column(String(255))
    contact_number = Column(String(20))
    email_contact = Column(String(255))

    user = relationship("User", back_populates="emergency_contacts")


class PanicInfo(Base):
    __tablename__ = "panic_info"
    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    pressed_at = Column(TIMESTAMP, server_default=text("now()"))
    latitude = Column(DECIMAL(9, 6))
    longitude = Column(DECIMAL(9, 6))
    status = Column(String(50))
    emergency_contact_notified = Column(Boolean, default=False)
    hotline_notified = Column(Boolean, default=False)
    additional_notes = Column(Text)

    user = relationship("User", back_populates="panic_info")


class DangerZone(Base):
    __tablename__ = "danger_zones"
    id = Column(Integer, primary_key=True, index=True)
    location_name = Column(String(255))
    longitude = Column(DECIMAL(9, 6))
    latitude = Column(DECIMAL(9, 6))
    description = Column(Text)
    reported_count = Column(Integer, server_default=text("0"))


class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True)
    panic_info_id = Column(Integer, ForeignKey("panic_info.id"))
    message = Column(Text)
    created_at = Column(TIMESTAMP, server_default=text("now()"))

class UserTokenTable(Base):
    __tablename__ = "user_tokens"
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'))
    access_token = Column(String(450), primary_key=True)
    refresh_token = Column(String(450), nullable=False)
    status = Column(Boolean)
    created_date = Column(DateTime, default=datetime.datetime.now)

class LegalAidTokenTable(Base):
    __tablename__ = "legal_aid_tokens"
    provider_id = Column(UUID(as_uuid=True), ForeignKey('legal_aid_providers.id'))
    access_token = Column(String(450), primary_key=True)
    refresh_token = Column(String(450), nullable=False)
    status = Column(Boolean)
    created_date = Column(DateTime, default=datetime.datetime.now)