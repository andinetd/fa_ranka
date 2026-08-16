"""
CBE (Commercial Bank of Ethiopia) SMS Parser GUI
A desktop application to parse CBE SMS messages,
fetch receipt pages or PDFs, and extract information.

Requirements:
pip install requests pypdf2

This GUI provides:
1. SMS parsing - extract link, amount, ref from SMS text
2. Receipt fetch - download receipt page or PDF from the CBE link
3. Receipt extraction - extract all info from the fetched receipt
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import re
import requests
import os
import tempfile
import threading
from urllib.parse import urlparse

# PDF parsing
try:
    import PyPDF2
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False
    print("Warning: PyPDF2 not available. Trying pdftotext...")

# Try pdftotext as fallback
PDFTOTEXT_AVAILABLE = None
try:
    import subprocess
    result = subprocess.run(['which', 'pdftotext'], capture_output=True, text=True)
    PDFTOTEXT_AVAILABLE = result.returncode == 0
except:
    pass

# ============== CONFIGURATION ==============
TEMP_DIR = tempfile.gettempdir()
RECEIPTS_DIR = os.path.join(TEMP_DIR, "cbe_receipts")
os.makedirs(RECEIPTS_DIR, exist_ok=True)

# ============== SMS PARSING FUNCTIONS ==============

def extract_receipt_url(sms_text):
    """Extract receipt URL from CBE SMS"""
    url_pattern = re.compile(
        r'https?://(?:apps\.cbe\.com\.et:100/\?id=|apps\.cbe\.com\.et:100/BranchReceipt/|mbreciept\.cbe\.com\.et/)[^\s]+',
        re.IGNORECASE
    )
    match = url_pattern.search(sms_text)
    return match.group(0) if match else None


def extract_sender_name(sms_text):
    """Extract sender/recipient name from SMS"""
    pattern = re.compile(r'Dear\s+([A-Za-z\s]+?)(?:\s+You have|$)', re.IGNORECASE)
    match = pattern.search(sms_text)
    return match.group(1).strip() if match else None


def extract_transaction_ref(sms_text):
    """Extract transaction reference from CBE SMS or URL"""
    # First try to get from URL
    url = extract_receipt_url(sms_text)
    if url:
        ref_pattern = re.compile(r'(FT[A-Z0-9]+)', re.IGNORECASE)
        match = ref_pattern.search(url)
        if match:
            return match.group(1)
    
    # Try from SMS text directly (Ref No FT...)
    ref_pattern = re.compile(r'Ref\s*No\.?\s*(FT[A-Z0-9]+)', re.IGNORECASE)
    match = ref_pattern.search(sms_text)
    if match:
        return match.group(1)
    
    return None


def extract_amount(sms_text):
    """Extract amount from SMS"""
    pattern1 = re.compile(r'ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    pattern2 = re.compile(r'total\s+of\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    pattern3 = re.compile(r'transferred\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    
    match = pattern2.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    
    match = pattern3.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    
    match = pattern1.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    
    return None


def extract_counterparty(sms_text):
    """Extract counterparty name from SMS"""
    pattern1 = re.compile(r'to\s+([A-Za-z\s]+?)\s+on', re.IGNORECASE)
    pattern2 = re.compile(r'from\s+([A-Za-z\s]+?),', re.IGNORECASE)
    pattern3 = re.compile(r'\(([A-Za-z\s]+?)\)', re.IGNORECASE)
    
    match = pattern1.search(sms_text)
    if match:
        return match.group(1).strip()
    
    match = pattern2.search(sms_text)
    if match:
        return match.group(1).strip()
    
    match = pattern3.search(sms_text)
    if match:
        return match.group(1).strip()
    
    return None


def extract_direction(sms_text):
    """Determine if transaction is credit or debit"""
    text_lower = sms_text.lower()
    if 'credited' in text_lower:
        return 'Credit'
    elif 'debited' in text_lower or 'transferred' in text_lower or 'successfully transferred' in text_lower:
        return 'Debit'
    return 'Unknown'


def extract_date_time(sms_text):
    """Extract date and time from SMS"""
    # Pattern: "21/01/2026 at 19:11:33"
    pattern = re.compile(r'(\d{1,2}/\d{1,2}/\d{4})\s+at\s+(\d{1,2}:\d{2}:\d{2})')
    match = pattern.search(sms_text)
    if match:
        return match.group(1), match.group(2)
    
    # Alternative: "14/02/2026 at 12:34:37"
    pattern2 = re.compile(r'(\d{1,2}/\d{1,2}/\d{4}),\s*(\d{1,2}:\d{2}:\d{2})')
    match = pattern2.search(sms_text)
    if match:
        return match.group(1), match.group(2)
    
    return None, None


def extract_account(sms_text):
    """Extract source account number from SMS"""
    pattern = re.compile(r'account\s+1[\d*]+', re.IGNORECASE)
    match = pattern.search(sms_text)
    return match.group(0) if match else None


def extract_accounts(sms_text):
    """Extract both source and destination account numbers"""
    pattern = re.compile(r'account\s+1[\d*]+', re.IGNORECASE)
    matches = pattern.findall(sms_text)
    return matches if matches else []


def extract_balance(sms_text):
    """Extract balance from SMS"""
    # Pattern: "Current Balance is ETB 443.39"
    pattern = re.compile(r'Current\s+Balance\s+(?:is\s+)?ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    match = pattern.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    return None


def extract_commission_vat(sms_text):
    """Extract commission, VAT, and Disaster Recovery from SMS"""
    commission = None
    vat = None
    disaster_recovery = None
    
    comm_pattern = re.compile(r'(?:S\.?|Service\s+)charge\s+of\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    match = comm_pattern.search(sms_text)
    if match:
        commission = float(match.group(1).replace(',', ''))
    
    vat_pattern = re.compile(r'VAT\s*\([^)]*\)\s*of\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    match = vat_pattern.search(sms_text)
    if not match:
        vat_pattern = re.compile(r'\d+%\s*VAT\s+of\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
        match = vat_pattern.search(sms_text)
    if match:
        vat = float(match.group(1).replace(',', ''))
    
    dr_pattern = re.compile(r'Disaster Recovery\(5%\) of\s+([\d.]+)', re.IGNORECASE)
    match = dr_pattern.search(sms_text)
    if match:
        disaster_recovery = float(match.group(1).replace(',', ''))
    
    return commission, vat, disaster_recovery


def extract_text_from_html(html_content):
    """Convert an HTML receipt page into normalized plain text."""
    html_content = re.sub(r'<script[^>]*>.*?</script>', '', html_content, flags=re.DOTALL | re.IGNORECASE)
    html_content = re.sub(r'<style[^>]*>.*?</style>', '', html_content, flags=re.DOTALL | re.IGNORECASE)
    html_content = re.sub(r'<br\s*/?>', '\n', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'</p>', '\n', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'</div>', '\n', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'<[^>]+>', ' ', html_content)
    html_content = re.sub(r'\s+', ' ', html_content)
    return html_content.strip()


def parse_cbe_receipt_html(html_content):
    """Parse CBE receipt page HTML and extract receipt fields."""
    result = {
        'source': 'html_parse',
        'referenceNumber': None,
        'customerName': None,
        'payerName': None,
        'payerAccount': None,
        'receiverName': None,
        'receiverAccount': None,
        'paymentDate': None,
        'paymentTime': None,
        'reason': None,
        'transferredAmount': None,
        'serviceCharge': None,
        'vat': None,
        'totalAmount': None,
        'amountWords': None,
        'bankName': 'Commercial Bank of Ethiopia',
    }

    if not html_content or len(html_content.strip()) < 50:
        result['error'] = 'Empty HTML response'
        return result

    text = extract_text_from_html(html_content)

    match = re.search(r'(?:VAT\s*Receipt\s*No|Reference\s*No\.?\s*\(VAT\s*Invoice\s*No\)|VAT\s*Invoice\s*No)\s*[:\-]?\s*([A-Z0-9]+)', text, re.IGNORECASE)
    if match:
        result['referenceNumber'] = match.group(1).strip()

    match = re.search(r'Customer\s+Name\s*[:\-]\s*([^\n]+?)(?:\s+(?:Region|City|Sub\s*City|Wereda|VAT|TIN|Branch)\b|$)', text, re.IGNORECASE)
    if match:
        result['customerName'] = match.group(1).strip()

    match = re.search(r'Payer\s*[:\-]\s*([^\n]+?)(?:\s+Account\b|\s+Receiver\b|\s+Payment\s+Date\b|$)', text, re.IGNORECASE)
    if match:
        result['payerName'] = match.group(1).strip()

    match = re.search(r'Account\s*[:\-]\s*([0-9*]+)', text, re.IGNORECASE)
    if match:
        result['payerAccount'] = match.group(1).strip()

    match = re.search(r'Receiver\s*[:\-]\s*([^\n]+?)(?:\s+Account\b|\s+Payment\s+Date\b|\s+Reason\b|$)', text, re.IGNORECASE)
    if match:
        result['receiverName'] = match.group(1).strip()

    accounts = re.findall(r'Account\s*[:\-]?\s*([0-9*]+)', text, re.IGNORECASE)
    if len(accounts) >= 2:
        result['receiverAccount'] = accounts[1].strip()
    elif accounts:
        result['payerAccount'] = result['payerAccount'] or accounts[0].strip()

    match = re.search(
        r'Payment\s*Date\s*&\s*Time\s*[:\-]?\s*([A-Za-z]{3}\s+\d{1,2},\s+\d{4}|\d{1,2}/\d{1,2}/\d{4})[,\s]+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
        text,
        re.IGNORECASE
    )
    if match:
        result['paymentDate'] = match.group(1).strip()
        result['paymentTime'] = match.group(2).strip()

    match = re.search(r'Reason\s*/\s*Type\s*of\s*service\s*[:\-│\|:票]\s*([^\n]+?)(?:\s+Transferred\b|\s+Service\s+Charge\b|\s+Total\s+amount\b|$)', text, re.IGNORECASE)
    if match:
        result['reason'] = match.group(1).strip()

    match = re.search(r'Transferred\s*Amount\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
    if match:
        result['transferredAmount'] = float(match.group(1).replace(',', ''))

    match = re.search(r'Service\s*Charge(?:\s*\(.*?\))?\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
    if match:
        result['serviceCharge'] = float(match.group(1).replace(',', ''))

    match = re.search(r'15%\s*VAT(?:\s*(?:and|of|on)\s*(?:Disaster\s+Recovery|Commission))?\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
    if match:
        result['vat'] = float(match.group(1).replace(',', ''))

    match = re.search(r"Total\s*amount\s*debited\s*from\s*customer(?:'s|s)?\s*account\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB", text, re.IGNORECASE)
    if match:
        result['totalAmount'] = float(match.group(1).replace(',', ''))
    else:
        match = re.search(r'Total\s*amount\s*debited\s*[:\-]?\s*([\d,]+\.?\d*)\s*ETB', text, re.IGNORECASE)
        if match:
            result['totalAmount'] = float(match.group(1).replace(',', ''))

    match = re.search(r'Amount\s+in\s+Word\s*[:\-]?\s*([^\n]+)', text, re.IGNORECASE)
    if match:
        result['amountWords'] = match.group(1).strip()

    return result


# ============== PDF DOWNLOAD ==============

def convert_new_url_to_old(url):
    """Convert new mbreciept.cbe.com.et URL to old apps.cbe.com.et:100 PDF URL"""
    # New format: https://mbreciept.cbe.com.et/FT26105GLH8B-80095039
    # Old format: https://apps.cbe.com.et:100/?id=FT26105GLH8B80095039
    url_lower = url.lower()
    if 'mbreciept.cbe.com.et/' in url_lower:
        parts = url.split('/')[-1].split('-')
        if len(parts) >= 2:
            ref = parts[0]
            account = parts[1]
            return f'https://apps.cbe.com.et:100/?id={ref}{account}'
    
    # BranchReceipt format: https://apps.cbe.com.et:100/BranchReceipt/FT260708V0GH&80095039
    if 'branchreceipt' in url_lower:
        # Extract ref and account from BranchReceipt URL
        match = re.search(r'BranchReceipt/([^&]+)&(.+)', url, re.IGNORECASE)
        if match:
            ref = match.group(1)
            account = match.group(2)
            return f'https://apps.cbe.com.et:100/?id={ref}{account}'
    
    return url


def download_cbe_receipt(url, filename=None, timeout=30):
    """Download a CBE receipt page or PDF."""
    try:
        url = convert_new_url_to_old(url)
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        }
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()

        content_type = response.headers.get('Content-Type', '').lower()
        body_start = response.content[:16].lstrip()
        is_pdf = content_type.startswith('application/pdf') or body_start.startswith(b'%PDF-')
        is_html = 'text/html' in content_type or (not is_pdf and response.text.lstrip().startswith('<'))

        if filename is None:
            ref = extract_transaction_ref(url) or "receipt"
            extension = '.pdf' if is_pdf else '.html'
            filename = os.path.join(RECEIPTS_DIR, f"{ref}{extension}")

        os.makedirs(os.path.dirname(filename), exist_ok=True)
        if is_pdf:
            with open(filename, 'wb') as f:
                f.write(response.content)
        elif is_html:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(response.text)
        else:
            with open(filename, 'wb') as f:
                f.write(response.content)

        return filename
    except Exception as e:
        print(f"Download error: {e}")
        return None


# ============== PDF PARSING ==============

def parse_cbe_pdf(pdf_path):
    """
    Parse CBE PDF receipt and extract all fields.
    Returns a dictionary with all extracted information.
    """
    result = {
        'source': 'pdf_parse',
        'referenceNumber': None,
        'payerName': None,
        'payerAccount': None,
        'receiverName': None,
        'receiverAccount': None,
        'paymentDate': None,
        'paymentTime': None,
        'reason': None,
        'transferredAmount': None,
        'commission': None,
        'vat': None,
        'totalAmount': None,
    }
    
    text = None
    
    if PDF_AVAILABLE:
        try:
            with open(pdf_path, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                text = ""
                for page in reader.pages:
                    text += page.extract_text() + "\n"
        except Exception as e:
            result['error'] = str(e)
    
    if not text and PDFTOTEXT_AVAILABLE:
        import subprocess as sp
        try:
            proc_result = sp.run(
                ['pdftotext', '-layout', pdf_path, '-'],
                capture_output=True, text=True, timeout=30
            )
            if proc_result.returncode == 0:
                text = proc_result.stdout
        except Exception as e:
            result['error'] = str(e)
    
    if not text:
        result['error'] = "No PDF parsing available"
        return result
    
    try:
        
        print(f"PDF Text length: {len(text)}")
        
        # Extract Reference Number
        patterns = [
            re.compile(r'Reference\s*No\.\s*\(VAT\s*Invoice\s*No\)\s*([A-Z0-9]+)'),
            re.compile(r'VAT\s*Invoice\s*No\s*([A-Z0-9]+)'),
            re.compile(r'FT[0-9A-Z]+'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['referenceNumber'] = match.group(1).strip()
                break
        
        # Extract Payer Name
        patterns = [
            re.compile(r'Payer\s+([A-Za-z0-9\s]+?)(?=\n|Account|$)'),
            re.compile(r'Customer\s*Name:\s*([A-Za-z\s]+?)(?:\n|$)'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['payerName'] = match.group(1).strip()
                break
        
        # Extract Payer Account
        match = re.search(r'Account\s*([A-Z\*0-9]{4,15})', text)
        if match:
            result['payerAccount'] = match.group(1)
        
        # Extract Receiver Name
        patterns = [
            re.compile(r'Receiver\s+([A-Za-z0-9\s]+?)(?=\n|Account|$)'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['receiverName'] = match.group(1).strip()
                break
        
        # Extract Receiver Account (second account)
        accounts = re.findall(r'Account\s*([A-Z\*0-9]{4,15})', text)
        if len(accounts) >= 2:
            result['receiverAccount'] = accounts[1]
        
        # Extract Date/Time
        patterns = [
            re.compile(r'Payment\s*Date\s*&\s*Time\s+(\d{1,2}/\d{1,2}/\d{4}),\s*(\d{1,2}:\d{2}:\d{2}\s*[AP]M)'),
            re.compile(r'Payment\s*Date\s*&\s*Time\s+(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}:\d{2})'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['paymentDate'] = match.group(1)
                result['paymentTime'] = match.group(2)
                break
        
        # Extract Reason
        patterns = [
            re.compile(r'Reason\s*/\s*Type\s*of\s*service\s+(.+?)(?:\nTransferred|\s+Transferred)'),
            re.compile(r'Reason\s*/\s*Type\s*of\s*service\s+([A-Za-z]+)'),
            re.compile(r'Reason\s*/\s*Type\s*of\s*service\s*\n\s*(.+)'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['reason'] = match.group(1).strip().replace('\n', ' ')
                break
        
        # Extract Transferred Amount
        match = re.search(r'Transferred\s*Amount\s+([\d,]+\.?\d*)\s*ETB', text)
        if match:
            result['transferredAmount'] = float(match.group(1).replace(',', ''))
        
        # Extract Commission
        match = re.search(r'Commission\s*or\s*Service\s*Charge\s+([\d,]+\.?\d*)\s*ETB', text)
        if match:
            result['commission'] = float(match.group(1).replace(',', ''))
        
        # Extract VAT
        match = re.search(r'15%\s*VAT\s*on\s*Commission\s+([\d,]+\.?\d*)\s*ETB', text)
        if match:
            result['vat'] = float(match.group(1).replace(',', ''))
        
        # Extract Total Amount
        patterns = [
            re.compile(r'Total\s*amount\s*debited\s+from\s*customers?\s*account\s+([\d,]+\.?\d*)\s*ETB'),
            re.compile(r'Total\s*amount\s*debited\s+([\d,]+\.?\d*)\s*ETB'),
        ]
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                result['totalAmount'] = float(match.group(1).replace(',', ''))
                break
        
    except Exception as e:
        result['error'] = str(e)
    
    return result


def extract_total_amount(sms_text):
    """Extract total amount debited from SMS"""
    pattern = re.compile(r'total\s+of\s+ETB\s*([\d,]+\.?\d*)', re.IGNORECASE)
    match = pattern.search(sms_text)
    if match:
        return float(match.group(1).replace(',', ''))
    return None


def extract_payment_date_time(sms_text):
    """Extract payment date and time from new format SMS"""
    date_pattern = re.compile(r'Payment\s+Date[:\s]+(\d{1,2}/\d{1,2}/\d{4})', re.IGNORECASE)
    time_pattern = re.compile(r'Payment\s+Time[:\s]+(\d{1,2}:\d{2}(:\d{2})?)', re.IGNORECASE)
    
    date_match = date_pattern.search(sms_text)
    time_match = time_pattern.search(sms_text)
    
    if date_match:
        return date_match.group(1), time_match.group(1) if time_match else None
    
    date_pattern2 = re.compile(r'Payment\s+Date[:\s]+([A-Za-z]+\s+\d{1,2},\s+\d{4},\s+[\d:]+(?:\s*[AP]M)?)', re.IGNORECASE)
    match = date_pattern2.search(sms_text)
    if match:
        full_date = match.group(1)
        time_pattern = re.compile(r'([\d:]+(?:\s*[AP]M)?)$', re.IGNORECASE)
        time_match = time_pattern.search(full_date.strip())
        date_only = full_date
        time_only = None
        if time_match:
            time_only = time_match.group(1).strip()
            date_only = full_date.replace(time_match.group(1), '').strip().rstrip(',')
        return date_only, time_only
    
    return None, None


def extract_reason(sms_text):
    """Extract reason / type of service"""
    pattern = re.compile(r'Reason\s*/\s*Type\s*of\s*Service[:\s]+([^\n]+)', re.IGNORECASE)
    match = pattern.search(sms_text)
    return match.group(1).strip() if match else None


def parse_sms_complete(sms_text):
    """Parse all fields from SMS text"""
    result = {
        'source': 'sms_parse',
        'receipt_url': None,
        'reference_number': None,
        'amount': None,
        'direction': None,
        'sender_name': None,
        'counterparty': None,
        'source_account': None,
        'destination_account': None,
        'payment_date': None,
        'payment_time': None,
        'reason': None,
        'balance': None,
        'transferred_amount': None,
        'service_charge': None,
        'vat': None,
        'disaster_recovery': None,
        'total_amount_debited': None,
    }
    
    result['receipt_url'] = extract_receipt_url(sms_text)
    result['reference_number'] = extract_transaction_ref(sms_text)
    result['sender_name'] = extract_sender_name(sms_text)
    result['counterparty'] = extract_counterparty(sms_text)
    accounts = extract_accounts(sms_text)
    result['source_account'] = accounts[0] if len(accounts) > 0 else None
    result['destination_account'] = accounts[1] if len(accounts) > 1 else None
    
    # Try new format first (Payment Date/Time), fallback to old format
    payment_date, payment_time = extract_payment_date_time(sms_text)
    if not payment_date:
        payment_date, payment_time = extract_date_time(sms_text)
    result['payment_date'] = payment_date
    result['payment_time'] = payment_time
    
    result['reason'] = extract_reason(sms_text)
    result['balance'] = extract_balance(sms_text)
    result['service_charge'], result['vat'], result['disaster_recovery'] = extract_commission_vat(sms_text)
    
    result['transferred_amount'] = extract_amount(sms_text)
    result['total_amount_debited'] = extract_total_amount(sms_text)
    result['amount'] = result['transferred_amount']
    
    result['direction'] = extract_direction(sms_text)
    
    return result


# ============== GUI APPLICATION ==============

class CBEParserGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("CBE SMS Parser - Receipt Fetch & Extract")
        self.root.geometry("900x700")
        self.root.configure(bg='#f0f0f0')
        
        # Style
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('Title.TLabel', font=('Arial', 14, 'bold'), background='#f0f0f0')
        style.configure('Header.TLabel', font=('Arial', 12, 'bold'), background='#f0f0f0')
        style.configure('TButton', font=('Arial', 11))
        
        # Main container
        main_frame = ttk.Frame(root, padding=20)
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title = ttk.Label(main_frame, text="CBE SMS Parser - Extract Link & Fetch Receipt", 
                         style='Title.TLabel')
        title.pack(pady=(0, 20))
        
        # SMS Input Section
        sms_frame = ttk.LabelFrame(main_frame, text="1. Paste CBE SMS", padding=15)
        sms_frame.pack(fill=tk.BOTH, expand=False, pady=(0, 10))
        
        self.sms_text = scrolledtext.ScrolledText(sms_frame, height=6, font=('Courier', 10))
        self.sms_text.pack(fill=tk.BOTH, expand=True)
        self.sms_text.insert(tk.END, "Paste your CBE SMS here...\n\nExample (New Format):\nDear Andinet Dereje Mengist You have successfully transferred ETB 1,901.20 from account 1**5039 to account 1**4476 (Sara Kidanie Sertie).\nRef No: FT26105GLH8B-80095039\nPayment Date: 25/03/2026\nPayment Time: 14:30:00\nReason / Type of Service: Personal Transfer\nService charge of ETB 1.00 and VAT(15%) of ETB0.15 and Disaster Recovery(5%) of 0.05 with total of ETB1901.20\nYour current balance is ETB1,500.54.\nThanks for Banking with CBE.\nhttps://Mbreciept.cbe.com.et/FT26105GLH8B-80095039")
        
        # Buttons
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.parse_btn = ttk.Button(btn_frame, text="Parse SMS", command=self.parse_sms)
        self.parse_btn.pack(side=tk.LEFT, padx=5)
        
        self.download_btn = ttk.Button(btn_frame, text="Fetch Receipt", 
                                      command=self.download_receipt, state=tk.DISABLED)
        self.download_btn.pack(side=tk.LEFT, padx=5)
        
        self.extract_btn = ttk.Button(btn_frame, text="Extract Receipt Info", 
                                      command=self.extract_pdf, state=tk.DISABLED)
        self.extract_btn.pack(side=tk.LEFT, padx=5)
        
        self.clear_btn = ttk.Button(btn_frame, text="Clear", command=self.clear_all)
        self.clear_btn.pack(side=tk.LEFT, padx=5)
        
        # Results Section
        results_frame = ttk.LabelFrame(main_frame, text="2. Parsed Results", padding=15)
        results_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # SMS Results
        self.sms_results_text = scrolledtext.ScrolledText(results_frame, height=8, 
                                                           font=('Courier', 10))
        self.sms_results_text.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # PDF Results
        pdf_frame = ttk.LabelFrame(main_frame, text="3. Receipt Extraction Results", padding=15)
        pdf_frame.pack(fill=tk.BOTH, expand=True)
        
        self.pdf_results_text = scrolledtext.ScrolledText(pdf_frame, height=8, 
                                                          font=('Courier', 10))
        self.pdf_results_text.pack(fill=tk.BOTH, expand=True)
        
        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, 
                             relief=tk.SUNKEN, anchor=tk.W)
        status_bar.pack(fill=tk.X, pady=(10, 0))
        
        # Data storage
        self.sms_data = None
        self.pdf_data = None
        self.pdf_path = None
    
    def set_status(self, message):
        self.status_var.set(message)
        self.root.update()
    
    def parse_sms(self):
        """Parse SMS text"""
        sms_text = self.sms_text.get("1.0", tk.END).strip()
        if not sms_text:
            messagebox.showwarning("Warning", "Please paste an SMS first")
            return
        
        self.set_status("Parsing SMS...")
        
        try:
            self.sms_data = parse_sms_complete(sms_text)
            
            # Display SMS results
            self.sms_results_text.delete("1.0", tk.END)
            self.sms_results_text.insert(tk.END, "=== SMS PARSING RESULTS ===\n\n")
            
            for key, value in self.sms_data.items():
                if value is not None:
                    self.sms_results_text.insert(tk.END, f"{key}: {value}\n")
            
            # Enable download button if URL found
            if self.sms_data.get('receipt_url'):
                self.download_btn.config(state=tk.NORMAL)
                self.set_status(f"SMS parsed. URL found: {self.sms_data['receipt_url'][:50]}...")
            else:
                self.download_btn.config(state=tk.DISABLED)
                self.set_status("SMS parsed. No receipt URL found.")
            
        except Exception as e:
            messagebox.showerror("Error", f"Error parsing SMS: {e}")
            self.set_status("Error")
    
    def download_receipt(self):
        """Fetch the receipt page or PDF."""
        if not self.sms_data or not self.sms_data.get('receipt_url'):
            return
        
        url = self.sms_data['receipt_url']
        self.set_status("Fetching receipt...")
        
        # Run in thread
        def download_thread():
            try:
                self.pdf_path = download_cbe_receipt(url)
                self.root.after(0, self.download_complete)
            except Exception as e:
                self.root.after(0, lambda: self.download_error(str(e)))
        
        threading.Thread(target=download_thread, daemon=True).start()
    
    def download_complete(self):
        """Handle receipt fetch complete."""
        if self.pdf_path and os.path.exists(self.pdf_path):
            self.extract_btn.config(state=tk.NORMAL)
            if self.pdf_path.lower().endswith('.pdf'):
                self.set_status(f"Receipt PDF downloaded: {self.pdf_path}")
            else:
                self.set_status(f"Receipt page downloaded: {self.pdf_path}")
            
            # Show in results
            self.pdf_results_text.delete("1.0", tk.END)
            self.pdf_results_text.insert(tk.END, f"Receipt downloaded successfully!\n\n")
            self.pdf_results_text.insert(tk.END, f"Path: {self.pdf_path}\n\n")
            self.pdf_results_text.insert(tk.END, "Click 'Extract Receipt Info' to parse the receipt content.\n")
        else:
            messagebox.showerror("Error", "Failed to fetch receipt")
            self.set_status("Download failed")
    
    def download_error(self, error):
        messagebox.showerror("Error", f"Download error: {error}")
        self.set_status("Download error")
    
    def extract_pdf(self):
        """Extract information from the downloaded receipt."""
        if not self.pdf_path or not os.path.exists(self.pdf_path):
            messagebox.showwarning("Warning", "No receipt downloaded yet")
            return
        
        self.set_status("Extracting receipt content...")
        
        # Run in thread
        def extract_thread():
            try:
                if self.pdf_path.lower().endswith('.pdf'):
                    self.pdf_data = parse_cbe_pdf(self.pdf_path)
                else:
                    with open(self.pdf_path, 'r', encoding='utf-8', errors='ignore') as f:
                        html_content = f.read()
                    self.pdf_data = parse_cbe_receipt_html(html_content)
                self.root.after(0, self.extract_complete)
            except Exception as e:
                self.root.after(0, lambda: self.extract_error(str(e)))
        
        threading.Thread(target=extract_thread, daemon=True).start()
    
    def extract_complete(self):
        """Handle extraction complete"""
        self.pdf_results_text.delete("1.0", tk.END)
        
        if self.pdf_data.get('error'):
            self.pdf_results_text.insert(tk.END, f"Error: {self.pdf_data['error']}\n")
            self.set_status("Extraction error")
            return
        
        self.pdf_results_text.insert(tk.END, "=== RECEIPT EXTRACTION RESULTS ===\n\n")
        
        for key, value in self.pdf_data.items():
            if value is not None:
                self.pdf_results_text.insert(tk.END, f"{key}: {value}\n")
        
        self.set_status("Extraction complete!")
        
        # Show comparison
        if self.sms_data and self.pdf_data:
            self.pdf_results_text.insert(tk.END, "\n=== COMPARISON ===\n")
            self.pdf_results_text.insert(tk.END, f"SMS Amount: {self.sms_data.get('amount')}\n")
            self.pdf_results_text.insert(tk.END, f"Receipt Amount: {self.pdf_data.get('transferredAmount')}\n")
            self.pdf_results_text.insert(tk.END, f"SMS Ref: {self.sms_data.get('transaction_ref')}\n")
            self.pdf_results_text.insert(tk.END, f"Receipt Ref: {self.pdf_data.get('referenceNumber')}\n")
    
    def extract_error(self, error):
        messagebox.showerror("Error", f"Extraction error: {error}")
        self.set_status("Extraction error")
    
    def clear_all(self):
        """Clear all fields"""
        self.sms_text.delete("1.0", tk.END)
        self.sms_results_text.delete("1.0", tk.END)
        self.pdf_results_text.delete("1.0", tk.END)
        self.sms_data = None
        self.pdf_data = None
        self.pdf_path = None
        self.download_btn.config(state=tk.DISABLED)
        self.extract_btn.config(state=tk.DISABLED)
        self.set_status("Ready")


def main():
    root = tk.Tk()
    app = CBEParserGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
