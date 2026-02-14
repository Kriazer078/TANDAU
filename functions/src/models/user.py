from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    display_name: str = Field(min_length=2)
    role: Optional[str] = "user" # user or admin

class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    role: Optional[str] = None
