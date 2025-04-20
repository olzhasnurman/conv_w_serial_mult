from PIL import Image

# 🔧 Set your image file and output text file here
INPUT_IMAGE_PATH = "rgb_nu.jpg"
OUTPUT_TXT_PATH = "input_x.txt"

def export_rgb_to_txt(image_path, output_path):
    # Open image and convert to RGB
    img = Image.open(image_path).convert("RGB")
    width, height = img.size
    pixels = img.load()

    with open(output_path, 'w') as f:
        # Write header
        f.write(f"{height} {width} 3\n")

        # Write pixel values row by row
        for y in range(height):
            row_values = []
            for x in range(width):
                r, g, b = pixels[x, y]
                row_values.extend([str(r), str(g), str(b)])
            f.write(' '.join(row_values) + '\n')

    print(f"RGB values exported to: {output_path}")

# Run the function
export_rgb_to_txt(INPUT_IMAGE_PATH, OUTPUT_TXT_PATH)

