import os
import glob
from PIL import Image
from rembg import remove, new_session

def process_image(input_path, output_path, session):
    # Read the image
    with open(input_path, 'rb') as i:
        input_data = i.read()
    
    # Remove background
    output_data = remove(input_data, session=session)
    
    # Write the output with transparency
    with open(output_path, 'wb') as o:
        o.write(output_data)
        
    print(f"Processed: {output_path}")

def crop_and_resize(image_path, size=(128, 128)):
    # Open the transparent PNG
    img = Image.open(image_path)
    
    # Get bounding box of the non-transparent area
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        
    # Resize keeping aspect ratio
    img.thumbnail(size, Image.Resampling.LANCZOS)
    
    img.save(image_path, "PNG")

def main():
    brain_dir = r"C:\Users\User.DESKTOP-T27SALG\.gemini\antigravity\brain\38fc1059-6286-43f5-80a6-716228d7aae4"
    output_dir = r"assets\icons\3d"
    os.makedirs(output_dir, exist_ok=True)
    
    files = glob.glob(os.path.join(brain_dir, "icon_3d_*.png"))
    
    session = new_session('u2net')
    
    for f in files:
        # e.g. icon_3d_target_1776403447611.png -> target.png
        filename = os.path.basename(f)
        parts = filename.split('_')
        # name logic: parts = ['icon', '3d', 'target', '1776403447611.png']
        # we want to save it as target.png
        if len(parts) >= 4:
            base_name = parts[2]
            output_path = os.path.join(output_dir, f"{base_name}.png")
            
            process_image(f, output_path, session)
            crop_and_resize(output_path, size=(128, 128))

if __name__ == "__main__":
    main()
