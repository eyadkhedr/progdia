import os
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Directory containing your images
image_dir = 'assets/images'

def clean_name_for_id(name):
    # Remove file extension, replace spaces and special chars with underscores
    name = name.lower()
    name = name.replace('.png', '')
    name = name.replace(' ', '_')
    # Remove any special characters that might cause issues
    name = ''.join(c for c in name if c.isalnum() or c == '_')
    return name

def guess_type(name):
    name = name.lower()
    if 'tie' in name: return 'tie'
    if 'shirt' in name or 'blouse' in name or 'sleeveless' in name: return 'shirt'
    if 'shoes' in name: return 'shoes'
    if 'hat' in name: return 'hat'
    if 'pants' in name: return 'pants'
    if 'skirt' in name: return 'skirt'
    if 'jacket' in name: return 'jacket'
    if 'glasses' in name: return 'glasses'
    return 'misc'

def guess_price(name):
    name = name.lower()
    base_price = 0
    
    # Base prices by type
    if 'tie' in name:
        base_price = 600
        if 'plain' in name: base_price -= 100
    
    elif 'shirt' in name or 'blouse' in name:
        base_price = 1000
        if 'sleeveless' in name: base_price = 800
        if 'casual' in name: base_price -= 100
        if 'classic' in name: base_price += 200
    
    elif 'shoes' in name:
        base_price = 700
        if 'classic' in name: base_price += 200
    
    elif 'hat' in name:
        base_price = 800
        if 'cowboy' in name: base_price += 300
        if 'casual' in name: base_price -= 100
        if 'girly' in name: base_price += 100
    
    elif 'pants' in name:
        base_price = 1200
        if 'classic' in name: base_price += 200
        if 'slip' in name: base_price -= 100
    
    elif 'skirt' in name:
        base_price = 1100
    
    elif 'jacket' in name:
        base_price = 1500
    
    elif 'glasses' in name:
        base_price = 900
    
    else:
        base_price = 1000

    # Color modifiers
    if any(color in name for color in ['purple', 'cyan']):
        base_price += 100  # Premium colors
    
    # Style modifiers
    if 'classic' in name:
        base_price += 200
    
    return base_price

# Process and upload items
for file_name in os.listdir(image_dir):
    if file_name.endswith('.png'):
        name = file_name.replace('.png', '').replace('_', ' ')
        doc_id = clean_name_for_id(file_name)  # Use cleaned filename as document ID
        type_ = guess_type(name)
        price = guess_price(name)
        
        doc = {
            'name': name,
            'type': type_,
            'price': price,
            'image': f'assets/images/{file_name}',
            'displayed_image': f'assets/images/display_{file_name}',
        }
        
        # Print preview of what will be uploaded
        print(f'Adding {name}:')
        print(f'  ID: {doc_id}')
        print(f'  Type: {type_}')
        print(f'  Price: {price}')
        print('---')
        
        # Upload to Firestore with custom document ID
        db.collection('shop_items').document(doc_id).set(doc)

print('Upload complete!')