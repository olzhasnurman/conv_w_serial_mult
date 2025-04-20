from PIL import Image
import numpy as np

# 🔧 Input and output file names
INPUT_TXT_PATH = "output_fpga.txt"
#INPUT_TXT_PATH = "edges.txt"
OUTPUT_IMAGE_PATH = "filtered_image.png"
#OUTPUT_IMAGE_PATH = "filtered_image2.png"

def reconstruct_rgb_image(txt_path, output_image_path):
    with open(txt_path, 'r') as f:
        # Read header
        header = f.readline()
        height, width, channels = map(int, header.strip().split())
        assert channels == 3, "Only RGB images are supported"

        # Read pixel data
        pixel_data = []
        for _ in range(height):
            row = list(map(int, f.readline().strip().split()))
            pixel_data.extend(row)

    # Convert to NumPy array and reshape
    image_array = np.array(pixel_data, dtype=np.uint16).reshape((height, width, 3))

    # Normalize to 0–255
    max_val = image_array.max()
    if max_val == 0:
        max_val = 1  # Avoid division by zero

    normalized = (image_array / max_val) * 255.0
    normalized = np.clip(normalized, 0, 255).astype(np.uint8)

    # Create and save image
    img = Image.fromarray(normalized, 'RGB')
    img.save(output_image_path)

    print(f"Image saved as {output_image_path}")

# Run it
reconstruct_rgb_image(INPUT_TXT_PATH, OUTPUT_IMAGE_PATH)

