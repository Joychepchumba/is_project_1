from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Database URLs 
##SQLALCHEMY_DATABASE_URL = "postgresql://postgres:19419@localhost:5432/femicide_safety_db"  # Local PostgreSQL
SQLALCHEMY_DATABASE_URL = "postgresql://postgres.ngfpaioekpicyvocxsbn:sAzJmU70ydh9QOsQ@aws-0-eu-north-1.pooler.supabase.com:5432/postgres"  # Supabase (Connection Pooling)"  # Supabase

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()