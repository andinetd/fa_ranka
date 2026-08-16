"""
Awash Bank SMS Parser GUI
A desktop application to parse Awash Bank SMS messages, 
download receipt images, and extract information using OCR.

Requirements:
pip install requests pytesseract pillow

You also need Tesseract OCR installed on your system:
- Windows: https://github.com/UB-Mannheim/tesseract/wiki
- Add tesseract to PATH or set TESSERACT_CMD path below
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import re
import requests
import os
import tempfile
from urllib.parse import urlparse
import threading

# Try to import pytesseract for OCR
try:
    import pytesseract
    from PIL import Image, ImageEnhance, ImageFilter
    OCR_IMPORTED = True
except ImportError:
    OCR_IMPORTED = False
    print("Warning: pytesseract or PIL not available. OCR will be simulated.")

# ============== CONFIGURATION ==============
TESSERACT_PATH = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Check if tesseract is available
if os.path.exists(TESSERACT_PATH):
    try:
        import pytesseract
        from PIL import Image
        pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH
        TESSERACT_AVAILABLE = True
        print(f"Tesseract found at: {TESSERACT_PATH}")
    except ImportError as e:
        print(f"Warning: pytesseract or PIL not available: {e}")
else:
    print(f"Warning: Tesseract not found at {TESSERACT_PATH}. OCR will use simulation mode.")

# ============== CONSTANTS ==============
TEMP_DIR = tempfile.gettempdir()
RECEIPTS_DIR = os.path.join(TEMP_DIR, "awash_receipts")
os.makedirs(RECEIPTS_DIR, exist_ok=True)


# ============== SMS PARSING FUNCTIONS ==============

def extract_receipt_url(sms_text):
    """Extract receipt URL from Awash SMS"""
    # Match URLs starting with awashpay.awashbank.com
    url_pattern = re.compile(
        r'(https?://awashpay\.awashbank\.com:\d+/[A-Za-z0-9\-/_]+)',
        re.IGNORECASE
    )
    match = url_pattern.search(sms_text)
    return match.group(1) if match else None


def extract_amount(sms_text):
    """Extract amount from SMS"""
    # Pattern 1: "ETB 2,000" or "ETB-500.00"
    pattern1 = re.compile(r'ETB[-]?\s*([\d,]+\.?\d*)', re.IGNORECASE)
    # Pattern 2: "2000.00 ETB"
    pattern2 = re.compile(r'([\d,]+\.?\d*)\s*ETB', re.IGNORECASE)
    
    match = pattern1.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    
    match = pattern2.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    
    return None


def extract_transaction_id(sms_text):
    """Extract transaction ID from SMS"""
    # Pattern 1: "Txn ID: 251222074633844"
    pattern1 = re.compile(r'Txn ID:\s*([0-9]+)', re.IGNORECASE)
    # Pattern 2: "REF 260..."
    pattern2 = re.compile(r'REF\s*([0-9]+)', re.IGNORECASE)
    
    match = pattern1.search(sms_text)
    if match:
        return match.group(1)
    
    match = pattern2.search(sms_text)
    if match:
        return match.group(1)
    
    return None


def extract_counterparty(sms_text):
    """Extract counterparty name from SMS"""
    # Pattern 1: "from DEREJE MENGIST on"
    pattern1 = re.compile(r'from\s+([A-Za-z\s]+?)\s+on', re.IGNORECASE)
    # Pattern 2: "To 1000581944776 (RIYAD SHEREFA RESHID)"
    pattern2 = re.compile(r'To\s+[0-9]+\s+\(([A-Za-z\s]+)\)', re.IGNORECASE)
    
    match = pattern1.search(sms_text)
    if match:
        return match.group(1).strip()
    
    match = pattern2.search(sms_text)
    if match:
        return match.group(1).strip()
    
    return None


def extract_direction(sms_text):
    """Determine if transaction is credit or debit"""
    text_lower = sms_text.lower()
    if 'credited' in text_lower or 'received' in text_lower:
        return 'Credit'
    elif 'debited' in text_lower or 'transferred' in text_lower:
        return 'Debit'
    return 'Unknown'


def extract_date_time(sms_text):
    """Extract date and time from SMS"""
    # Pattern: "2025-12-22 07:46:29"
    pattern = re.compile(r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})')
    match = pattern.search(sms_text)
    if match:
        return match.group(1), match.group(2)
    return None, None


# ============== RECEIPT DOWNLOAD ==============

# ============== HTML PARSING (Alternative to image) ==============

def parse_sms_for_receipt_fields(sms_text):
    """
    Parse receipt-like fields directly from SMS text.
    Used when HTML receipt is not accessible.
    """
    result = {
        'source': 'sms_parse',
        'transaction_id': None,
        'date': None,
        'time': None,
        'from_account': None,
        'to_account': None,
        'amount': None,
        'commission': None,
        'vat': None,
        'total': None,
        'reason': None,
        'transaction_type': None,
        'beneficiary_account': None,
        'beneficiary_bank': None,
        'till_number': None,
        'tin': None,
        'vat_reg': None,
    }
    
    print(f"DEBUG: parse_sms_for_receipt_fields called with: {sms_text[:100]}...")
    
    # Extract amount
    match = re.search(r'ETB\s*([\d,]+(?:\.\d+)?)', sms_text, re.IGNORECASE)
    if match:
        try:
            result['amount'] = float(match.group(1).replace(',', ''))
            print(f"Found amount: {result['amount']}")
        except:
            pass
    
    # Extract transaction ID from URL
    url_match = re.search(r'awashpay\.awashbank\.com:\d+/([A-Za-z0-9\-]+)', sms_text, re.IGNORECASE)
    if url_match:
        result['transaction_id'] = url_match.group(1)
        print(f"Found transaction_id: {result['transaction_id']}")
    
    # Extract date/time
    match = re.search(r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})', sms_text)
    if match:
        result['date'] = match.group(1)
        result['time'] = match.group(2)
        print(f"Found date/time: {result['date']} {result['time']}")
    
    # Beneficiary Account - "To 1000732946725 (MR ZAKIR...)"
    match = re.search(r'To\s+([0-9]+)\s*\(', sms_text, re.IGNORECASE)
    if match:
        result['beneficiary_account'] = match.group(1)
        print(f"Found beneficiary_account: {result['beneficiary_account']}")
    
    # Beneficiary Bank - "In Commercial Bank of Ethiopia"
    match = re.search(r'In\s+([A-Za-z][A-Za-z\s]+?)(?:\.|\s+Your|\s+VAT|\s+Receipt|\s+Contact)', sms_text, re.IGNORECASE)
    if match:
        result['beneficiary_bank'] = match.group(1).strip()
        print(f"Found beneficiary_bank: {result['beneficiary_bank']}")
    
    # To account (name in parentheses)
    match = re.search(r'To\s+[0-9]+\s*\(([A-Za-z\s]+)\)', sms_text, re.IGNORECASE)
    if match:
        result['to_account'] = match.group(1).strip()
        print(f"Found to_account: {result['to_account']}")
    
    # Commission and VAT (if present in SMS)
    match = re.search(r'Commission\s*([\d,]+(?:\.\d+)?)', sms_text, re.IGNORECASE)
    if match:
        try:
            result['commission'] = float(match.group(1).replace(',', ''))
            print(f"Found commission: {result['commission']}")
        except:
            pass
    
    match = re.search(r'VAT\s*([\d,]+(?:\.\d+)?)', sms_text, re.IGNORECASE)
    if match:
        try:
            result['vat'] = float(match.group(1).replace(',', ''))
            print(f"Found vat: {result['vat']}")
        except:
            pass
    
    # Transaction type - for transfers to other banks
    if 'other bank' in sms_text.lower():
        result['transaction_type'] = 'Bank Transfer'
        print(f"Found transaction_type: {result['transaction_type']}")
    
    print(f"DEBUG: parse_sms_for_receipt_fields result: {result}")
    return result


def get_html_content(url, timeout=30):
    """Get the HTML content of a receipt URL"""
    try:
        import warnings
        warnings.filterwarnings('ignore')
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        }
        session = requests.Session()
        response = session.get(url, headers=headers, timeout=timeout, verify=False)
        response.raise_for_status()
        
        # Check if it's HTML
        if 'text/html' in response.headers.get('content-type', ''):
            return response.text
        return None
    except Exception as e:
        print(f"Error getting HTML: {e}")
        return None


def parse_receipt_html(html_content, sms_text=None):
    """
    Parse transaction data directly from the HTML page or SMS text.
    The Awash receipt page contains all transaction data in the HTML.
    This is an alternative to downloading and OCR-ing the image.
    
    Args:
        html_content: The HTML content from the receipt URL
        sms_text: Optional SMS text for fallback parsing when HTML is empty
    """
    # First check if HTML is empty or too short
    if not html_content or len(html_content.strip()) < 100:
        # Try parsing directly from SMS text
        if sms_text:
            return parse_sms_for_receipt_fields(sms_text)
        return {
            'source': 'empty_html',
            'error': 'Empty HTML response',
            'transaction_id': None,
            'date': None,
            'time': None,
            'from_account': None,
            'to_account': None,
            'amount': None,
            'commission': None,
            'vat': None,
            'total': None,
            'reason': None,
            'transaction_type': None,
            'beneficiary_account': None,
            'beneficiary_bank': None,
            'till_number': None,
            'tin': None,
            'vat_reg': None,
        }
    
    result = {
        'source': 'html_parse',
        'raw_html': html_content[:5000],  # Save first 5000 chars for debugging
        'transaction_id': None,
        'date': None,
        'time': None,
        'from_account': None,
        'to_account': None,
        'amount': None,
        'commission': None,
        'vat': None,
        'total': None,
        'reason': None,
        'transaction_type': None,
        'beneficiary_account': None,
        'beneficiary_bank': None,
        'till_number': None,
        'tin': None,
        'vat_reg': None,
    }
    
    # First, extract all text content by stripping HTML
    def extract_text(html):
        # Remove script and style
        html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL | re.IGNORECASE)
        html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL | re.IGNORECASE)
        # Replace divs and brs with newlines
        html = re.sub(r'<br\s*/?>', '\n', html, flags=re.IGNORECASE)
        html = re.sub(r'</p>', '\n', html, flags=re.IGNORECASE)
        html = re.sub(r'</div>', '\n', html, flags=re.IGNORECASE)
        html = re.sub(r'<[^>]+>', ' ', html)
        html = re.sub(r'\s+', ' ', html)
        return html.strip()
    
    text = extract_text(html_content)
    print(f"Extracted {len(text)} chars of text from HTML")
    print(f"DEBUG: Text content: {text[:500]}...")
    
    # Transaction ID - look for "Transaction ID :" or "Transaction ID :"
    match = re.search(r'Transaction\s*ID\s*:\s*([A-Za-z0-9\-]+)', text, re.IGNORECASE)
    if match:
        result['transaction_id'] = match.group(1).strip()
        print(f"Found Transaction ID: {result['transaction_id']}")
    
    # Date and Time - look for "Transaction Time :" or "Transaction Date :" (handles both formats)
    # Format 1: "Transaction Time : 2026-01-02 08:44:39 PM"
    # Format 2: "Transaction Date : 2026-03-06 17:50:49"
    match = re.search(r'Transaction\s*Time\s*:\s*(\d{4}-\d{2}-\d{2})\s+(\d{1,2}:\d{2}:\d{2}\s*(?:AM|PM)?)', text, re.IGNORECASE)
    if match:
        result['date'] = match.group(1).strip()
        result['time'] = match.group(2).strip()
        print(f"Found Date/Time: {result['date']} {result['time']}")
    
    # Try Transaction Date format too
    if not result.get('date'):
        match = re.search(r'Transaction\s*Date\s*:\s*(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})', text, re.IGNORECASE)
        if match:
            result['date'] = match.group(1).strip()
            result['time'] = match.group(2).strip()
            print(f"Found Date/Time: {result['date']} {result['time']}")
    
    # Amount - look for "Amount : XX.XX ETB"
    match = re.search(r'Amount\s*:\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
    if match:
        try:
            result['amount'] = float(match.group(1).replace(',', ''))
            print(f"Found Amount: {result['amount']}")
        except:
            pass
    
    # Commission - look for "Commission :"
    match = re.search(r'Commission\s*:\s*([\d,]+\.?\d*)', text, re.IGNORECASE)
    if match:
        try:
            result['commission'] = float(match.group(1).replace(',', ''))
            print(f"Found Commission: {result['commission']}")
        except:
            pass
    
    # VAT
    match = re.search(r'VAT\s*:\s*([\d,]+\.?\d*)', text, re.IGNORECASE)
    if match:
        try:
            result['vat'] = float(match.group(1).replace(',', ''))
            print(f"Found VAT: {result['vat']}")
        except:
            pass
    
    # Total
    match = re.search(r'Total\s*:\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
    if match:
        try:
            result['total'] = float(match.group(1).replace(',', ''))
            print(f"Found Total: {result['total']}")
        except:
            pass
    
    # Reason - look for "Reason :" - handle multiple formats
    # Format 1: "Reason : Er Transaction ID : ..."
    # Format 2: "Reason : Card Sender Name : ..."
    match = re.search(r'Reason\s*:\s*([A-Za-z0-9\s]+?)(?:\s+(?:Transaction|Sender|Beneficiary|Till|Number)|\n|$)', text, re.IGNORECASE)
    if match:
        result['reason'] = match.group(1).strip()
        print(f"Found Reason: {result['reason']}")
    
    # From/Sender - look for "Sender Name :" or "Customer Name :"
    # Also try "Sender" field in HTML
    match = re.search(r'Sender\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Transaction|Sender|Beneficiary|Till|Number|Account)|\n|$)', text, re.IGNORECASE)
    if match:
        result['from_account'] = match.group(1).strip()
        print(f"Found From (Sender): {result['from_account']}")
    
    # Try Customer Name if not found
    if not result.get('from_account'):
        match = re.search(r'Customer\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Branch|City|VAT|TIN)|\n|$)', text, re.IGNORECASE)
        if match:
            result['from_account'] = match.group(1).strip()
            print(f"Found From (Customer): {result['from_account']}")
    
    # Account number - look for "Account No :" or "Account No:/No"
    match = re.search(r'Account\s*(?:No\.?|No/)?:?\s*([0-9xX\*]+)', text, re.IGNORECASE)
    if match:
        # Store the masked account number if from_account not set
        if not result.get('from_account'):
            result['from_account'] = match.group(1).strip()
        print(f"Found Account: {match.group(1)}")
    
    # To/Beneficiary - look for "Beneficiary name :" or "Beneficiary Name :"
    # Also try "Receiver" format in the HTML
    match = re.search(r'Receiver\s*Name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Account|Beneficiary|Reason|Transaction)|\n|$)', text, re.IGNORECASE)
    if match:
        result['to_account'] = match.group(1).strip()
        print(f"Found Receiver: {result['to_account']}")
    
    if not result.get('to_account'):
        match = re.search(r'Beneficiary\s*name\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Beneficiary|Account|Bank|Reason)|\n|$)', text, re.IGNORECASE)
        if match:
            result['to_account'] = match.group(1).strip()
            print(f"Found To (Beneficiary): {result['to_account']}")
    
    # Also try Merchant pattern
    if not result.get('to_account'):
        match = re.search(r'Merchant\s*:\s*([A-Za-z\s]+?)(?:\s+Till|Number|\n|$)', text, re.IGNORECASE)
        if match:
            result['to_account'] = match.group(1).strip()
            print(f"Found Merchant: {result['to_account']}")

    # Beneficiary Account - from SMS: "To 1000732946725 (MR ZAKIR...)"
    # Also check HTML as fallback - try "Receiver Account" format
    match = re.search(r'Receiver\s*Account\s*:\s*([0-9xX*]+)', text, re.IGNORECASE)
    if match:
        result['beneficiary_account'] = match.group(1).strip()
        print(f"Found Receiver Account: {result['beneficiary_account']}")
    
    if not result.get('beneficiary_account'):
        match = re.search(r'\bTo\s+([0-9]+)\s*\(', text, re.IGNORECASE)
        if match:
            result['beneficiary_account'] = match.group(1).strip()
            print(f"Found Beneficiary Account (SMS): {result['beneficiary_account']}")
        else:
            # Try HTML format as fallback
            match = re.search(r'Beneficiary\s*Account\s*:\s*([0-9]+)', text, re.IGNORECASE)
            if match:
                result['beneficiary_account'] = match.group(1).strip()
                print(f"Found Beneficiary Account: {result['beneficiary_account']}")
    
    # Beneficiary Bank - from SMS: "In Commercial Bank of Ethiopia"  
    # Also try "Receiver Bank" in HTML
    match = re.search(r'Receiver\s*Bank\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Reason|Transaction|ID)|\n|$)', text, re.IGNORECASE)
    if match:
        result['beneficiary_bank'] = match.group(1).strip()
        print(f"Found Receiver Bank: {result['beneficiary_bank']}")
    
    if not result.get('beneficiary_bank'):
        match = re.search(r'\bIn\s+([A-Za-z\s]+?)(?:\.|\s+Your|\s+VAT)', text, re.IGNORECASE)
        if match:
            result['beneficiary_bank'] = match.group(1).strip()
            print(f"Found Beneficiary Bank (SMS): {result['beneficiary_bank']}")
        else:
            # Try HTML format as fallback
            match = re.search(r'Beneficiary\s*Bank\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Reason|Transaction|ID)|\n|$)', text, re.IGNORECASE)
            if match:
                result['beneficiary_bank'] = match.group(1).strip()
                print(f"Found Beneficiary Bank: {result['beneficiary_bank']}")
    
    # Account number - look for "Account No :"
    match = re.search(r'Account\s*No\s*:\s*([0-9xX\*]+)', text, re.IGNORECASE)
    if match:
        # Store the masked account number
        if not result.get('from_account'):
            result['from_account'] = match.group(1).strip()
        print(f"Found Account: {match.group(1)}")
    
    # Transaction type - handles "Transaction Type : IPS Bank Transfer"
    # Stop at keywords like Amount, VAT, Sender, etc.
    match = re.search(r'Transaction\s*Type\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Amount|VAT|Sender|Beneficiary|Reason|ID)|\n|$)', text, re.IGNORECASE)
    if match:
        result['transaction_type'] = match.group(1).strip()
        print(f"Found Transaction type: {result['transaction_type']}")
    
    # If not found, try the lowercase version
    if not result.get('transaction_type'):
        match = re.search(r'Transaction\s*type\s*:\s*([A-Za-z\s]+?)(?:\s+(?:Amount|VAT|Sender|Beneficiary|Reason|ID)|\n|$)', text, re.IGNORECASE)
        if match:
            result['transaction_type'] = match.group(1).strip()
            print(f"Found Transaction type: {result['transaction_type']}")
    
    # Company Name (from Company Information section)
    match = re.search(r'Company\s*Name\s*:\s*([A-Za-z\s]+?)(?:\n|$)', text, re.IGNORECASE)
    if match:
        result['company_name'] = match.group(1).strip()
        print(f"Found Company: {result['company_name']}")
    
    # Customer Name
    match = re.search(r'Customer\s*Name\s*:\s*([A-Za-z\s]+?)(?:\n|$)', text, re.IGNORECASE)
    if match:
        result['customer_name'] = match.group(1).strip()
        print(f"Found Customer: {result['customer_name']}")
    
    # Branch
    match = re.search(r'Branch\s*:\s*([A-Za-z\s]+?)(?:\n|$)', text, re.IGNORECASE)
    if match:
        result['branch'] = match.group(1).strip()
        print(f"Found Branch: {result['branch']}")
    
    # Till Number
    match = re.search(r'Till\s*Number\s*:\s*([0-9]+)', text, re.IGNORECASE)
    if match:
        result['till_number'] = match.group(1).strip()
        print(f"Found Till Number: {result['till_number']}")
    
    # TIN No
    match = re.search(r'(?:TIN|Tax)\s*(?:No|ID)\s*:\s*([0-9]+)', text, re.IGNORECASE)
    if match:
        result['tin'] = match.group(1).strip()
        print(f"Found TIN: {result['tin']}")
    
    # VAT Reg No
    match = re.search(r'VAT\s*Reg\s*No\s*:\s*([0-9\-]+)', text, re.IGNORECASE)
    if match:
        result['vat_reg'] = match.group(1).strip()
        print(f"Found VAT Reg: {result['vat_reg']}")
    
    return result


def download_receipt(url, timeout=30):
    """Download receipt image from URL"""
    try:
        print(f"Downloading receipt from: {url}")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
        }
        
        # Use session to maintain cookies
        session = requests.Session()
        
        # First, visit the page to get the HTML
        response = session.get(url, headers=headers, timeout=timeout, allow_redirects=True)
        response.raise_for_status()
        
        print(f"Content-Type: {response.headers.get('content-type', '')}")
        
        # Check if it's HTML (webpage with download button)
        content_preview = response.content[:200]
        if b'<!doctype' in content_preview.lower() or b'<html' in content_preview.lower():
            print("Got HTML page - looking for download button...")
            
            # Parse HTML to find image URL
            html_content = response.text
            
            # Try to find image in various ways
            image_url = None
            
            # Method 1: Look for <img> tag with src
            img_match = re.search(r'<img[^>]+src=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
            if img_match:
                image_url = img_match.group(1)
                print(f"Found image URL in <img> tag: {image_url}")
            
            # Method 2: Look for download link/button
            if not image_url:
                download_match = re.search(r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>.*?(download|receipt|image|png).*?</a>', html_content, re.IGNORECASE)
                if download_match:
                    image_url = download_match.group(1)
                    print(f"Found download link: {image_url}")
            
            # Method 3: Look for form action (POST download)
            if not image_url:
                form_match = re.search(r'<form[^>]+action=["\']([^"\']+)["\']', html_content, re.IGNORECASE)
                if form_match:
                    form_action = form_match.group(1)
                    # Handle relative URLs
                    if not form_action.startswith('http'):
                        from urllib.parse import urljoin
                        form_action = urljoin(url, form_action)
                    print(f"Found form action: {form_action}")
                    
                    # Submit form to get image (find the button/input that triggers download)
                    # Look for submit button or hidden inputs
                    submit_match = re.search(r'<button[^>]*>.*?(download|get).*?</button>', html_content, re.IGNORECASE)
                    if submit_match:
                        # Try GET request to form action
                        image_url = form_action
            
            # Method 4: Look for meta refresh (redirect to image)
            if not image_url:
                meta_match = re.search(r'<meta[^>]+content=["\']?[^>]*url=([^"\']+)["\']?', html_content, re.IGNORECASE)
                if meta_match:
                    image_url = meta_match.group(1)
                    print(f"Found meta refresh URL: {image_url}")
            
            # Method 5: Look for base64 encoded image
            if not image_url:
                base64_match = re.search(r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)', html_content)
                if base64_match:
                    import base64
                    print("Found base64 encoded image")
                    # Decode and save
                    image_data = base64.b64decode(base64_match.group(1))
                    # Save as PNG
                    url_hash = hash(url)
                    filepath = os.path.join(RECEIPTS_DIR, f"receipt_{url_hash}.png")
                    with open(filepath, 'wb') as f:
                        f.write(image_data)
                    print(f"Saved base64 image to: {filepath}")
                    return filepath
            
            # If we found an image URL, fetch it
            if image_url:
                # Handle relative URLs
                if not image_url.startswith('http'):
                    from urllib.parse import urljoin
                    image_url = urljoin(url, image_url)
                
                print(f"Fetching image from: {image_url}")
                
                # Use the same session to maintain cookies
                img_response = session.get(image_url, headers=headers, timeout=timeout)
                img_response.raise_for_status()
                content = img_response.content
            else:
                print("Could not find image URL in HTML")
                print(f"HTML preview: {html_content[:500]}")
                return None
        else:
            # Direct image response
            content = response.content
        
        # Determine file extension
        content_type = response.headers.get('content-type', '')
        ext = '.png'  # Default
        
        if 'image/png' in content_type:
            ext = '.png'
        elif 'image/jpeg' in content_type or 'image/jpg' in content_type:
            ext = '.jpg'
        else:
            # Check actual content bytes
            if content[:4] == b'\x89PNG':
                ext = '.png'
            elif content[:2] == b'\xff\xd8':
                ext = '.jpg'
        
        # Ensure extension has a dot
        if not ext.startswith('.'):
            ext = '.' + ext
        
        print(f"Detected extension: {ext}")
        
        # Save to file - use URL hash for unique filename
        url_hash = hash(url)
        filename = f"receipt_{url_hash}{ext}"
        filepath = os.path.join(RECEIPTS_DIR, filename)
        
        print(f"Saving to: {filepath}")
        
        with open(filepath, 'wb') as f:
            f.write(content)
        
        # Verify file was saved
        if os.path.exists(filepath):
            file_size = os.path.getsize(filepath)
            print(f"File saved successfully: {filepath} ({file_size} bytes)")
            
            # Verify it's a valid image by checking magic bytes
            if file_size > 10:
                with open(filepath, 'rb') as f:
                    magic = f.read(10)
                    # PNG: 89 50 4E 47... (\x89PNG)
                    # JPG: FF D8 FF (\xff\xd8\xff)
                    # GIF: 47 49 46 38 (GIF8)
                    if magic[:2] == b'\x89PNG' or magic[:3] == b'\xff\xd8\xff' or magic[:6] == b'GIF89a' or magic[:6] == b'GIF87a':
                        print("Verified: Valid image file")
                    else:
                        print(f"WARNING: File may not be a valid image. Magic bytes: {magic[:10]}")
        else:
            print(f"ERROR: File was not saved!")
        
        return filepath
    except Exception as e:
        print(f"Error downloading receipt: {e}")
        return None


# ============== OCR PARSING ==============

def parse_receipt_image(image_path):
    """Parse receipt image using Tesseract OCR"""
    if not TESSERACT_AVAILABLE:
        return simulate_ocr_parse(image_path)
    
    try:
        # Check if file exists
        if not os.path.exists(image_path):
            return {'error': f'File not found: {image_path}', 'source': 'file_not_found'}
        
        # Check file size - if too small, it's probably an error page
        file_size = os.path.getsize(image_path)
        print(f"Image file size: {file_size} bytes")
        
        if file_size < 1000:
            # Read and check if it's HTML (error page)
            with open(image_path, 'r', errors='ignore') as f:
                content_preview = f.read(100)
                if '<html' in content_preview.lower() or '<!doctype' in content_preview.lower():
                    return {'error': 'Downloaded file is HTML, not an image', 'source': 'not_an_image'}
        
        # Try to load image with error handling
        try:
            image = Image.open(image_path)
            # Verify the image is valid by loading it
            image.load()
        except Exception as img_err:
            print(f"Error loading image: {img_err}")
            # Additional debug info - read first bytes of file
            try:
                with open(image_path, 'rb') as f:
                    magic = f.read(20)
                    print(f"File magic bytes: {magic}")
                    # Check if it's HTML
                    if b'<!DOCTYPE' in magic or b'<html' in magic.lower():
                        return {'error': 'Downloaded file is HTML, not an image', 'source': 'not_an_image'}
                    # Check if it's JSON/error response
                    try:
                        text = magic.decode('utf-8', errors='ignore')
                        if '{' in text or 'error' in text.lower():
                            return {'error': 'Server returned error response instead of image', 'source': 'server_error'}
                    except:
                        pass
            except:
                pass
            return {'error': f'Cannot identify image: {img_err}', 'source': 'image_error'}
        
        # Extract text using pytesseract with custom config
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(image, config=custom_config)
        
        print(f"OCR extracted {len(text)} characters")
        
        # Parse extracted text
        result = parse_ocr_text(text)
        
        # Also try to get detailed data with OCR
        try:
            data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
            result['ocr_confidence'] = sum(filter(None, data.get('conf', []))) / len(data.get('conf', [1]))
        except:
            result['ocr_confidence'] = 0
        
        return result
        
    except Exception as e:
        print(f"Error during OCR: {e}")
        import traceback
        traceback.print_exc()
        return {'error': str(e), 'source': 'tesseract_error'}


def preprocess_image(image):
    """Preprocess image for better OCR results"""
    # Convert to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize for better OCR (300 DPI is ideal)
    base_width = 1200
    w_percent = (base_width / float(image.size[0]))
    h_size = int((float(image.size[1]) * float(w_percent)))
    image = image.resize((base_width, h_size), Image.Resampling.LANCZOS)
    
    # Convert to grayscale
    image = image.convert('L')
    
    # Increase contrast
    enhancer = ImageEnhance.Contrast(image)
    image = enhancer.enhance(1.5)
    
    # Sharpen
    image = image.filter(ImageFilter.SHARPEN)
    
    return image


def parse_ocr_text(text):
    """Parse OCR extracted text to extract receipt data"""
    result = {
        'source': 'tesseract_ocr',
        'raw_text': text,
        'transaction_id': None,
        'date': None,
        'time': None,
        'from_account': None,
        'to_account': None,
        'amount': None,
        'commission': None,
        'vat': None,
        'total': None,
        'reason': None,
    }
    
    # Normalize text for easier matching
    text_lines = [line.strip() for line in text.split('\n') if line.strip()]
    
    # Search line by line for key data
    for i, line in enumerate(text_lines):
        line_lower = line.lower()
        
        # Transaction ID - look for "Transaction ID", "Txn ID", "Ref"
        if not result['transaction_id']:
            patterns = [
                r'Transaction ID[:\s]+([A-Za-z0-9\-]+)',
                r'Txn ID[:\s]+([A-Za-z0-9\-]+)',
                r'Reference[:\s]+([A-Za-z0-9\-]+)',
                r'Ref[:\s]+([A-Za-z0-9\-]+)',
            ]
            for pattern in patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['transaction_id'] = match.group(1)
                    break
        
        # Date and Time extraction - look for "Transaction Time" line first
        if not result['date']:
            # Check if this line contains Transaction Time
            if 'Transaction Time' in line or 'transaction time' in line.lower():
                # Extract both date and time from Transaction Time line
                datetime_match = re.search(r'(\d{4}-\d{2}-\d{2})', line)
                if datetime_match:
                    result['date'] = datetime_match.group(1)
                time_match = re.search(r'(\d{1,2}:\d{2}:?\d{0,2}\s*(?:AM|PM)?)', line, re.IGNORECASE)
                if time_match:
                    result['time'] = time_match.group(1).strip()
            # Skip lines with Reg Date or RegNo
            elif 'Reg Date' not in line and 'RegNo' not in line and 'Reg No' not in line:
                # Standalone date patterns
                date_match = re.search(r'(\d{4}-\d{2}-\d{2})', line)
                if date_match:
                    year = int(date_match.group(1)[:4])
                    if year > 2020:
                        result['date'] = date_match.group(1)
        
        # From Account
        if not result['from_account']:
            from_patterns = [
                r'From Account[:\s]+([0-9xX]+)',
                r'Payer Account[:\s]+([0-9xX]+)',
                r'Source Account[:\s]+([0-9xX]+)',
            ]
            for pattern in from_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['from_account'] = match.group(1)
                    break
        
        # To Account
        if not result['to_account']:
            to_patterns = [
                r'To Account[:\s]+([0-9xX]+)',
                r'Receiver Account[:\s]+([0-9xX]+)',
                r'Destination Account[:\s]+([0-9xX]+)',
            ]
            for pattern in to_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['to_account'] = match.group(1)
                    break
        
        # Reason / Transaction Type
        if not result['reason']:
            reason_patterns = [
                r'Transaction[\s/]Type[:\s]+(.+)',
                r'Transaction[\s/]Type (.+)',
            ]
            for pattern in reason_patterns:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    result['reason'] = match.group(1).strip()
                    break
    
    # Extract amounts - scan entire text for amount patterns
    # Pattern: "Amount 100 ETB"
    amount_pattern = re.compile(r'Amount[:\s]*(\d+(?:[,.]\d+)?)\s*ETB', re.IGNORECASE)
    for line in text_lines:
        match = amount_pattern.search(line)
        if match and result['amount'] is None:
            result['amount'] = float(match.group(1).replace(',', ''))
    
    # Commission - look for "Commission" or "Fee"
    comm_pattern = re.compile(r'(?:Commission|Fee)[:\s]*(\d+(?:[,.]\d+)?)\s*ETB', re.IGNORECASE)
    for line in text_lines:
        match = comm_pattern.search(line)
        if match:
            result['commission'] = float(match.group(1).replace(',', ''))
    
    # VAT - look for "VAT" followed by ETB
    vat_pattern = re.compile(r'VAT[:\s]*(\d+(?:[,.]\d+)?)\s*ETB', re.IGNORECASE)
    for line in text_lines:
        match = vat_pattern.search(line)
        if match:
            result['vat'] = float(match.group(1).replace(',', ''))
    
    # Total - look for "Total" or "Grand Total" followed by ETB
    total_pattern = re.compile(r'(?:Total|Grand Total)[:\s]*(\d+(?:[,.]\d+)?)\s*ETB', re.IGNORECASE)
    for line in text_lines:
        match = total_pattern.search(line)
        if match and result['total'] is None:
            result['total'] = float(match.group(1).replace(',', ''))
    
    # Calculate total if not found but amount exists
    if result['total'] is None and result['amount'] is not None:
        comm = result['commission'] or 0
        vat = result['vat'] or 0
        result['total'] = result['amount'] + comm + vat
    
    return result


def simulate_ocr_parse(image_path):
    """Simulate OCR parsing for testing when pytesseract is not available"""
    # This returns sample data to demonstrate the UI
    return {
        'source': 'simulated',
        'raw_text': 'Simulated OCR data (install pytesseract for real OCR)',
        'transaction_id': 'TXN1234567890',
        'date': '2025-12-22',
        'time': '07:46:29',
        'from_account': '013352xxxxx7300',
        'to_account': '1000123456789',
        'reason': 'Bank Transfer',
        'amount': 2000.00,
        'commission': 0.00,
        'vat': 0.00,
        'total': 2000.00,
    }


# ============== GUI APPLICATION ==============

class AwashParserGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Awash Bank SMS Parser")
        self.root.geometry("900x800")
        self.root.configure(bg="#f5f5f5")
        
        # Style configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('Title.TLabel', font=('Arial', 14, 'bold'), background='#f5f5f5')
        style.configure('TButton', font=('Arial', 11))
        style.configure('TLabel', font=('Arial', 10), background='#f5f5f5')
        
        # Main container
        main_frame = ttk.Frame(root, padding=20)
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = ttk.Label(main_frame, text="Awash Bank SMS & Receipt Parser", 
                                style='Title.TLabel', foreground='#e65100')
        title_label.pack(pady=(0, 20))
        
        # SMS Input Section
        sms_frame = ttk.LabelFrame(main_frame, text="SMS Input", padding=10)
        sms_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.sms_text = scrolledtext.ScrolledText(sms_frame, height=8, font=('Consolas', 10))
        self.sms_text.pack(fill=tk.X)
        self.sms_text.insert(tk.END, "Paste Awash Bank SMS message here...")
        
        # Parse Button
        self.parse_btn = ttk.Button(main_frame, text="Parse SMS & Download Receipt", 
                                     command=self.parse_sms)
        self.parse_btn.pack(pady=(0, 10))
        
        # Status Label
        self.status_label = ttk.Label(main_frame, text="Ready", foreground='gray')
        self.status_label.pack(pady=(0, 10))
        
        # Results Notebook (tabs)
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # SMS Results Tab
        self.sms_result_frame = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(self.sms_result_frame, text="SMS Data")
        
        # Receipt Data Tab
        self.receipt_frame = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(self.receipt_frame, text="Receipt OCR Data")
        
        # Initialize SMS results display
        self._init_sms_results()
        
        # Initialize receipt results display
        self._init_receipt_results()
        
        # Configure grid weights
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(3, weight=1)
    
    def _init_sms_results(self):
        """Initialize SMS results display widgets"""
        labels = ['Direction:', 'Amount:', 'Transaction ID:', 'Counterparty:', 'Date:', 'Time:', 'Receipt URL:']
        self.sms_labels = {}
        
        for i, label_text in enumerate(labels):
            row = i // 2
            col = (i % 2) * 2
            
            lbl = ttk.Label(self.sms_result_frame, text=label_text, font=('Arial', 10, 'bold'))
            lbl.grid(row=row, column=col, sticky=tk.W, padx=(0, 5), pady=5)
            
            val_lbl = ttk.Label(self.sms_result_frame, text="N/A", foreground='gray')
            val_lbl.grid(row=row, column=col+1, sticky=tk.W, padx=(0, 20), pady=5)
            
            key = label_text.rstrip(':').lower().replace(' ', '_')
            self.sms_labels[key] = val_lbl
    
    def _init_receipt_results(self):
        """Initialize receipt results display widgets"""
        labels = ['Transaction ID:', 'Date:', 'Time:', 'From Account:', 'To Account:', 
                  'Amount:', 'Commission:', 'VAT:', 'Total:', 'Reason:', 'Type:', 
                  'Beneficiary Acct:', 'Beneficiary Bank:', 'Till Number:', 'TIN:', 'VAT Reg:']
        self.receipt_labels = {}
        
        for i, label_text in enumerate(labels):
            row = i // 2
            col = (i % 2) * 2
            
            lbl = ttk.Label(self.receipt_frame, text=label_text, font=('Arial', 10, 'bold'))
            lbl.grid(row=row, column=col, sticky=tk.W, padx=(0, 5), pady=5)
            
            val_lbl = ttk.Label(self.receipt_frame, text="N/A", foreground='gray')
            val_lbl.grid(row=row, column=col+1, sticky=tk.W, padx=(0, 20), pady=5)
            
            key = label_text.rstrip(':').lower().replace(' ', '_')
            self.receipt_labels[key] = val_lbl
        
        # Raw text area
        ttk.Label(self.receipt_frame, text="Raw/Source:", font=('Arial', 10, 'bold')).grid(
            row=8, column=0, sticky=tk.W, pady=(10, 5))
        self.raw_ocr_text = scrolledtext.ScrolledText(self.receipt_frame, height=8, font=('Consolas', 9))
        self.raw_ocr_text.grid(row=9, column=0, columnspan=4, sticky=(tk.W, tk.E), pady=5)
    
    def parse_sms(self):
        """Parse SMS and download receipt"""
        sms_text = self.sms_text.get("1.0", tk.END).strip()
        
        if not sms_text or sms_text == "Paste Awash Bank SMS message here...":
            messagebox.showwarning("Warning", "Please paste an Awash Bank SMS message")
            return
        
        # Disable button during processing
        self.parse_btn.config(state=tk.DISABLED)
        self.status_label.config(text="Parsing SMS...", foreground='blue')
        
        # Run in separate thread
        thread = threading.Thread(target=self._parse_sms_thread, args=(sms_text,))
        thread.start()
    
    def _parse_sms_thread(self, sms_text):
        """Background thread for parsing"""
        try:
            # Parse SMS
            url = extract_receipt_url(sms_text)
            amount = extract_amount(sms_text)
            txn_id = extract_transaction_id(sms_text)
            counterparty = extract_counterparty(sms_text)
            direction = extract_direction(sms_text)
            date, time = extract_date_time(sms_text)
            
            # Update UI with SMS results
            self.root.after(0, self._update_sms_display, {
                'direction': direction,
                'amount': f"ETB {amount:,.2f}" if amount else "N/A",
                'transaction_id': txn_id or "N/A",
                'counterparty': counterparty or "N/A",
                'date': date or "N/A",
                'time': time or "N/A",
                'receipt_url': url or "N/A",
            })
            
            # Download and parse receipt if URL exists
            if url:
                self.root.after(0, self.status_label.config, 
                              ({"text": "Downloading receipt...", "foreground": "blue"},))
                
                receipt_path = download_receipt(url)
                print(f"DEBUG: download_receipt returned: {receipt_path}")
                
                # Check if download returned a file (could be image or HTML)
                if receipt_path:
                    self.root.after(0, self.status_label.config,
                                  ({"text": "Parsing receipt...", "foreground": "blue"},))
                    
                    receipt_data = parse_receipt_image(receipt_path)
                    print(f"DEBUG: parse_receipt_image returned: {receipt_data}")
                    
                    # If OCR fails or returns error, try HTML parsing instead
                    if 'error' in receipt_data or not receipt_data.get('transaction_id'):
                        print("DEBUG: OCR failed, trying HTML parsing...")
                        # Try to get HTML content and parse it
                        html_content = get_html_content(url)
                        if html_content:
                            print("DEBUG: Got HTML, parsing...")
                            receipt_data = parse_receipt_html(html_content, sms_text)
                            receipt_data['note'] = 'Parsed from HTML'
                            # Use the URL as the receipt path for display
                            receipt_path = url
                            print(f"DEBUG: HTML parsed, result: {receipt_data}")
                        else:
                            # HTML empty - fallback to SMS parsing
                            print("DEBUG: HTML empty, falling back to SMS parsing...")
                            receipt_data = parse_sms_for_receipt_fields(sms_text)
                            receipt_data['note'] = 'Parsed from SMS (HTML unavailable)'
                            receipt_path = url
                            print(f"DEBUG: SMS fallback result: {receipt_data}")
                else:
                    # Download failed, try HTML parsing directly
                    print("DEBUG: Download returned None, trying HTML parsing directly...")
                    html_content = get_html_content(url)
                    if html_content:
                        receipt_data = parse_receipt_html(html_content, sms_text)
                        receipt_data['note'] = 'Parsed from HTML (download failed)'
                        receipt_path = url
                        print(f"DEBUG: HTML parsed directly, result: {receipt_data}")
                    else:
                        # HTML empty - fallback to SMS parsing
                        print("DEBUG: HTML empty, falling back to SMS parsing...")
                        receipt_data = parse_sms_for_receipt_fields(sms_text)
                        receipt_data['note'] = 'Parsed from SMS (HTML unavailable)'
                        receipt_path = url
                        print(f"DEBUG: SMS fallback result: {receipt_data}")
                
                # Update receipt display if we have data
                if receipt_path or receipt_data.get('transaction_id'):
                    display_path = receipt_path if receipt_path else url
                    self.root.after(0, self._update_receipt_display, display_path, receipt_data)
                    
                    self.root.after(0, self.status_label.config,
                                  ({"text": "Complete!", "foreground": "green"},))
                else:
                    self.root.after(0, self.status_label.config,
                                  ({"text": "Failed to parse receipt", "foreground": "red"},))
            else:
                self.root.after(0, self.status_label.config,
                              ({"text": "No receipt URL found in SMS", "foreground": "orange"},))
            
        except Exception as e:
            self.root.after(0, self._show_error, str(e))
        
        finally:
            self.root.after(0, lambda: self.parse_btn.config(state=tk.NORMAL))
    
    def _update_sms_display(self, data):
        """Update SMS results display"""
        for key, value in data.items():
            if key in self.sms_labels:
                self.sms_labels[key].config(text=value, foreground='black')
        
        # Color code direction
        if data.get('direction') == 'Credit':
            self.sms_labels['direction'].config(foreground='green')
        elif data.get('direction') == 'Debit':
            self.sms_labels['direction'].config(foreground='red')
    
    def _update_receipt_display(self, image_path, data):
        """Update receipt OCR results display"""
        print(f"DEBUG: _update_receipt_display called with data keys: {list(data.keys())}")
        
        if 'error' in data:
            self.receipt_labels['transaction_id'].config(text=data['error'], foreground='red')
            return
        
        mapping = {
            'transaction_id': 'transaction_id',
            'date': 'date',
            'time': 'time',
            'from_account': 'from_account',
            'to_account': 'to_account',
            'amount': 'amount',
            'commission': 'commission',
            'vat': 'vat',
            'total': 'total',
            'reason': 'reason',
            'transaction_type': 'transaction_type',
            'beneficiary_acct': 'beneficiary_account',  # UI key -> data key
            'beneficiary_bank': 'beneficiary_bank',
            'till_number': 'till_number',
            'tin': 'tin',
            'vat_reg': 'vat_reg',
        }
        
        displayed_count = 0
        for key, data_key in mapping.items():
            value = data.get(data_key)
            print(f"DEBUG: Checking {key} = {value}")
            if value is not None and key in self.receipt_labels:
                if isinstance(value, float):
                    display = f"ETB {value:,.2f}"
                else:
                    display = str(value)
                self.receipt_labels[key].config(text=display, foreground='black')
                displayed_count += 1
                print(f"DEBUG: Set {key} to {display}")
        
        # Show raw text or note about source
        self.raw_ocr_text.delete("1.0", tk.END)
        raw_text = data.get('raw_text') or data.get('note') or data.get('source') or 'No text extracted'
        self.raw_ocr_text.insert(tk.END, raw_text)
        
        print(f"DEBUG: Displayed {displayed_count} fields")
        
        # Show raw text or note about source
        self.raw_ocr_text.delete("1.0", tk.END)
        raw_text = data.get('raw_text') or data.get('note') or data.get('source') or 'No text extracted'
        self.raw_ocr_text.insert(tk.END, raw_text)
        
        print(f"DEBUG: Displayed {displayed_count} fields")
        
        # Switch to receipt tab
        self.notebook.select(self.receipt_frame)
    
    def _show_error(self, message):
        """Show error message"""
        messagebox.showerror("Error", f"An error occurred: {message}")
        self.parse_btn.config(state=tk.NORMAL)


# ============== MAIN ==============

def main():
    root = tk.Tk()
    app = AwashParserGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()