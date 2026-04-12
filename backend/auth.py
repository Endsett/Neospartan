"""Authentication and authorization for NeoSpartan Backend."""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext

from config import settings


# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security scheme
security = HTTPBearer()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a hashed password."""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    
    return encoded_jwt


def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError:
        return None


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """Dependency to get current authenticated user from JWT token."""
    token = credentials.credentials
    
    payload = verify_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: no user ID",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check token expiration
    exp = payload.get("exp")
    if exp and datetime.utcnow().timestamp() > exp:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return {
        "id": user_id,
        "email": payload.get("email"),
        "role": payload.get("role", "user"),
    }


async def get_current_active_user(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    """Dependency to get current active user."""
    # Could add additional checks here (e.g., user not disabled)
    return current_user


async def require_admin(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    """Dependency to require admin role."""
    if current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user


# ============== Supabase Auth Integration ==============

class SupabaseAuth:
    """Integration with Supabase Auth for token validation."""
    
    @staticmethod
    def verify_supabase_token(token: str) -> Optional[Dict[str, Any]]:
        """Verify a Supabase JWT token."""
        try:
            # Supabase tokens use a specific JWT secret
            payload = jwt.decode(
                token,
                settings.supabase_jwt_secret,
                algorithms=["HS256"],
                audience="authenticated"
            )
            return payload
        except JWTError:
            return None
    
    @staticmethod
    def extract_user_from_token(token: str) -> Optional[Dict[str, Any]]:
        """Extract user info from Supabase token."""
        payload = SupabaseAuth.verify_supabase_token(token)
        if not payload:
            return None
        
        return {
            "id": payload.get("sub"),
            "email": payload.get("email"),
            "role": payload.get("role", "user"),
        }


async def get_current_user_supabase(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """Dependency to get current user from Supabase token."""
    token = credentials.credentials
    
    # First try Supabase token
    user = SupabaseAuth.extract_user_from_token(token)
    if user:
        return user
    
    # Fall back to our own JWT verification
    user = verify_token(token)
    if user:
        return {
            "id": user.get("sub"),
            "email": user.get("email"),
            "role": user.get("role", "user"),
        }
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
