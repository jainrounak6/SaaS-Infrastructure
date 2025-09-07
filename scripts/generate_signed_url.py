#!/usr/bin/env python3
"""
CloudFront Signed URL Generator
==============================

A reusable script to generate CloudFront signed URLs for private content.
Configure the variables below and run the script.

Usage:
    python3 generate_signed_url.py

Requirements:
    - boto3
    - cryptography
    - requests (for testing)
"""

import boto3
from botocore.signers import CloudFrontSigner
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
import datetime
import requests
import sys
import os

# =============================================================================
# CONFIGURATION - Update these values as needed
# =============================================================================

# CloudFront Configuration
CLOUDFRONT_DOMAIN = "du2p5bx4argje.cloudfront.net"
PUBLIC_KEY_ID = "K18PZB19JIHM6F"  # Working CloudFront Public Key ID

# Private Key Configuration
PRIVATE_KEY_PATH = "keys/CDN-KEYS/startup/dev/customer-one-dev-cloudfront-private.pem"

# File Configuration
FILE_NAME = "test-content.html"  # Change this to the file you want to access
DURATION_MINUTES = 5  # How long the signed URL should be valid

# Testing Configuration
TEST_URL = True  # Set to False to skip testing the generated URL

# =============================================================================
# SCRIPT LOGIC
# =============================================================================

def load_private_key(key_path):
    """Load the private key from file."""
    try:
        with open(key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(key_file.read(), password=None)
        return private_key
    except FileNotFoundError:
        print(f"❌ Error: Private key file not found at {key_path}")
        print("   Please check the PRIVATE_KEY_PATH configuration.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error loading private key: {e}")
        sys.exit(1)

def rsa_signer(message, private_key):
    """Sign a message using RSA."""
    return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())

def generate_signed_url(cloudfront_domain, public_key_id, private_key, file_name, duration_minutes):
    """Generate a CloudFront signed URL."""
    try:
        # Create CloudFront signer
        cloudfront_signer = CloudFrontSigner(public_key_id, lambda msg: rsa_signer(msg, private_key))
        
        # Generate signed URL
        url = f"https://{cloudfront_domain}/{file_name}"
        expire_date = datetime.datetime.utcnow() + datetime.timedelta(minutes=duration_minutes)
        
        signed_url = cloudfront_signer.generate_presigned_url(url, date_less_than=expire_date)
        
        return signed_url, expire_date
    except Exception as e:
        print(f"❌ Error generating signed URL: {e}")
        sys.exit(1)

def test_signed_url(signed_url):
    """Test the signed URL by making a request."""
    try:
        print("🔄 Testing signed URL...")
        response = requests.get(signed_url, timeout=10)
        
        print(f"📊 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SUCCESS! Signed URL is working!")
            print("📄 Content preview:")
            content = response.text
            if len(content) > 300:
                print(content[:300] + "...")
            else:
                print(content)
        else:
            print("❌ FAILED! Access denied or error occurred")
            print("📄 Response Content:")
            content = response.text
            if len(content) > 500:
                print(content[:500] + "...")
            else:
                print(content)
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Error testing URL: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

def main():
    """Main function."""
    print("🔐 CloudFront Signed URL Generator")
    print("=" * 50)
    print(f"File: {FILE_NAME}")
    print(f"CloudFront Domain: {CLOUDFRONT_DOMAIN}")
    print(f"Public Key ID: {PUBLIC_KEY_ID}")
    print(f"Duration: {DURATION_MINUTES} minutes")
    print(f"Private Key: {PRIVATE_KEY_PATH}")
    print()
    
    # Load private key
    print("🔑 Loading private key...")
    private_key = load_private_key(PRIVATE_KEY_PATH)
    print("✅ Private key loaded successfully")
    
    # Generate signed URL
    print("🔐 Generating signed URL...")
    signed_url, expire_date = generate_signed_url(
        CLOUDFRONT_DOMAIN, 
        PUBLIC_KEY_ID, 
        private_key, 
        FILE_NAME, 
        DURATION_MINUTES
    )
    
    print("✅ Signed URL generated successfully!")
    print(f"📅 Expires at: {expire_date}")
    print()
    print("🔗 Your Signed URL:")
    print(signed_url)
    print()
    
    # Test the URL if requested
    if TEST_URL:
        test_signed_url(signed_url)
        print()
    
    print("💡 Copy and paste the URL above into your browser to access the private content.")
    print(f"💡 This URL will work for {DURATION_MINUTES} minutes from now.")

if __name__ == "__main__":
    main()