from PIL import Image
import sys

def get_dominant_red(image_path):
    try:
        img = Image.open(image_path)
        img = img.convert("RGB")
        colors = img.getcolors(maxcolors=img.size[0] * img.size[1])
        
        # Filter for reddish colors
        red_candidates = []
        for count, color in colors:
            r, g, b = color
            # Define "red" as significantly more red than green/blue and high saturation
            if r > 150 and r > g * 1.5 and r > b * 1.5:
                red_candidates.append((count, color))
        
        if not red_candidates:
            print("No significant red found.")
            return

        # Sort by count (get most frequent red)
        red_candidates.sort(key=lambda x: x[0], reverse=True)
        
        # Get the top candidate
        top_color = red_candidates[0][1]
        hex_color = '#{:02x}{:02x}{:02x}'.format(*top_color)
        print(f"Dominant red: {hex_color} (RGB: {top_color})")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <image_path>")
    else:
        get_dominant_red(sys.argv[1])
