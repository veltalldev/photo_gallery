from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from typing import List, Set, Optional
import ipaddress
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

class IPWhitelistMiddleware(BaseHTTPMiddleware):
    def __init__(
        self,
        app,
        whitelist_file: Optional[str] = None,
        whitelist: Optional[List[str]] = None,
        always_allow: Optional[List[str]] = None
    ):
        super().__init__(app)
        self.allowed_ips: Set[ipaddress.IPv4Network] = set()
        self.always_allow = set(always_allow or ["127.0.0.1", "::1"])
        
        # Load IPs from whitelist file if provided
        if whitelist_file:
            self._load_from_file(whitelist_file)
            
        # Add IPs from direct whitelist if provided
        if whitelist:
            self._add_ips(whitelist)
            
        logger.info("IP Whitelist Middleware initialized with networks: %s", self.allowed_ips)

    def _load_from_file(self, file_path: str) -> None:
        """Load IP addresses from a file, one per line."""
        try:
            with open(file_path, 'r') as f:
                ips = [line.strip() for line in f.readlines() if line.strip() and not line.startswith('#')]
                self._add_ips(ips)
        except Exception as e:
            logger.error(f"Failed to load IP whitelist from file {file_path}: {e}")
            raise RuntimeError(f"Failed to load IP whitelist: {e}")

    def _add_ips(self, ips: List[str]) -> None:
        """Add IP addresses or networks to the whitelist."""
        for ip in ips:
            try:
                # Handle both individual IPs and CIDR notation
                network = ipaddress.IPv4Network(ip, strict=False)
                self.allowed_ips.add(network)
                logger.info(f"Added {network} to IP whitelist")
            except ValueError as e:
                logger.error(f"Invalid IP address or network '{ip}': {e}")
                raise ValueError(f"Invalid IP address or network '{ip}'")

    def _is_ip_allowed(self, ip: str) -> bool:
        """Check if an IP address is allowed."""
        if ip in self.always_allow:
            logger.info(f"Allowed request from always-allowed IP: {ip}")
            return True
            
        try:
            client_ip = ipaddress.IPv4Address(ip)
            allowed = any(client_ip in network for network in self.allowed_ips)
            if allowed:
                matching_networks = [net for net in self.allowed_ips if client_ip in net]
                logger.info(f"Allowed request from IP: {ip} (matched networks: {matching_networks})")
            else:
                logger.warning(f"Blocked request from non-whitelisted IP: {ip}")
            return allowed
        except ValueError:
            logger.warning(f"Invalid IP address format: {ip}")
            return False

    async def dispatch(self, request: Request, call_next):
        """Process the request and check if the client IP is whitelisted."""
        client_ip = request.client.host
        logger.info(f"Checking IP: {client_ip} for path: {request.url.path}")
        
        if not self._is_ip_allowed(client_ip):
            logger.warning(f"Access denied for IP: {client_ip} to path: {request.url.path}")
            raise HTTPException(
                status_code=403,
                detail="Access denied. Your IP is not whitelisted."
            )
        
        logger.info(f"Access granted for IP: {client_ip} to path: {request.url.path}")    
        return await call_next(request)

def setup_ip_whitelist(app, whitelist_file: Optional[str] = None, whitelist: Optional[List[str]] = None):
    """Helper function to set up IP whitelisting on a FastAPI app."""
    app.add_middleware(
        IPWhitelistMiddleware,
        whitelist_file=whitelist_file,
        whitelist=whitelist
    )