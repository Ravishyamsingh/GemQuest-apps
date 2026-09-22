import math
import os
from PIL import Image, ImageDraw, ImageFilter

SIZE = 128
CENTER = SIZE / 2.0

def create_radial_gradient(size, inner_color, outer_color):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    max_r = size / 2.0
    for r in range(int(max_r), 0, -1):
        ratio = r / max_r
        c = tuple(int(inner_color[i] * (1.0 - ratio) + outer_color[i] * ratio) for i in range(4))
        draw.ellipse([CENTER - r, CENTER - r, CENTER + r, CENTER + r], fill=c)
    return img

def draw_faceted_gem(filename, base_color, highlight_color, dark_color, shape_type="diamond"):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Outer subtle shadow
    shadow_img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_img)
    sdraw.ellipse([14, 18, 114, 118], fill=(0, 0, 0, 90))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(4))
    img.paste(shadow_img, (0, 0), shadow_img)

    if shape_type == "diamond":
        # Classic 6-sided brilliant hexagon
        outer_pts = [
            (64, 14), (108, 38), (108, 90), (64, 114), (20, 90), (20, 38)
        ]
        inner_pts = [
            (64, 34), (88, 50), (88, 78), (64, 94), (40, 78), (40, 50)
        ]
        # Base body
        draw.polygon(outer_pts, fill=base_color, outline=(255, 255, 255, 180), width=2)
        # Facets around inner table
        for i in range(6):
            p1 = outer_pts[i]
            p2 = outer_pts[(i+1)%6]
            p3 = inner_pts[(i+1)%6]
            p4 = inner_pts[i]
            c = highlight_color if i in [0, 5] else (dark_color if i in [2, 3] else base_color)
            draw.polygon([p1, p2, p3, p4], fill=c, outline=(255, 255, 255, 120), width=1)
        # Inner table
        draw.polygon(inner_pts, fill=highlight_color, outline=(255, 255, 255, 200), width=2)

    elif shape_type == "ruby":
        # Octagonal emerald-cut ruby
        outer_pts = [
            (44, 16), (84, 16), (112, 44), (112, 84), (84, 112), (44, 112), (16, 84), (16, 44)
        ]
        inner_pts = [
            (50, 34), (78, 34), (94, 50), (94, 78), (78, 94), (50, 94), (34, 78), (34, 50)
        ]
        draw.polygon(outer_pts, fill=base_color, outline=(255, 255, 255, 180), width=2)
        for i in range(8):
            p1 = outer_pts[i]
            p2 = outer_pts[(i+1)%8]
            p3 = inner_pts[(i+1)%8]
            p4 = inner_pts[i]
            c = highlight_color if i in [0, 7, 6] else (dark_color if i in [2, 3, 4] else base_color)
            draw.polygon([p1, p2, p3, p4], fill=c, outline=(255, 255, 255, 100), width=1)
        draw.polygon(inner_pts, fill=highlight_color, outline=(255, 255, 255, 220), width=2)

    elif shape_type == "emerald":
        # Square cushion cut
        outer_pts = [
            (24, 20), (104, 20), (112, 28), (112, 100), (104, 108), (24, 108), (16, 100), (16, 28)
        ]
        inner_pts = [
            (36, 32), (92, 32), (92, 96), (36, 96)
        ]
        draw.polygon(outer_pts, fill=base_color, outline=(255, 255, 255, 180), width=2)
        # Trapezoids
        draw.polygon([outer_pts[0], outer_pts[1], inner_pts[1], inner_pts[0]], fill=highlight_color)
        draw.polygon([outer_pts[2], outer_pts[3], inner_pts[2], inner_pts[1]], fill=dark_color)
        draw.polygon([outer_pts[4], outer_pts[5], inner_pts[3], inner_pts[2]], fill=dark_color)
        draw.polygon([outer_pts[6], outer_pts[7], inner_pts[0], inner_pts[3]], fill=highlight_color)
        draw.polygon(inner_pts, fill=base_color, outline=(255, 255, 255, 200), width=2)

    elif shape_type == "sapphire":
        # Oval / Round cushion
        draw.ellipse([18, 18, 110, 110], fill=base_color, outline=(255, 255, 255, 180), width=2)
        # Facet wedges
        inner_r = 32
        for i in range(8):
            ang1 = i * math.pi / 4.0
            ang2 = (i + 1) * math.pi / 4.0
            p1 = (64 + 46 * math.cos(ang1), 64 + 46 * math.sin(ang1))
            p2 = (64 + 46 * math.cos(ang2), 64 + 46 * math.sin(ang2))
            p3 = (64 + inner_r * math.cos(ang2), 64 + inner_r * math.sin(ang2))
            p4 = (64 + inner_r * math.cos(ang1), 64 + inner_r * math.sin(ang1))
            c = highlight_color if i in [5, 6, 7] else (dark_color if i in [1, 2, 3] else base_color)
            draw.polygon([p1, p2, p3, p4], fill=c, outline=(255, 255, 255, 90), width=1)
        draw.ellipse([64 - inner_r, 64 - inner_r, 64 + inner_r, 64 + inner_r], fill=highlight_color, outline=(255, 255, 255, 210), width=2)

    elif shape_type == "topaz":
        # Golden Triangle / Trilliant cut
        outer_pts = [(64, 14), (114, 104), (14, 104)]
        inner_pts = [(64, 46), (92, 90), (36, 90)]
        draw.polygon(outer_pts, fill=base_color, outline=(255, 255, 255, 180), width=2)
        draw.polygon([outer_pts[0], outer_pts[1], inner_pts[1], inner_pts[0]], fill=highlight_color, outline=(255,255,255,100), width=1)
        draw.polygon([outer_pts[1], outer_pts[2], inner_pts[2], inner_pts[1]], fill=dark_color, outline=(255,255,255,100), width=1)
        draw.polygon([outer_pts[2], outer_pts[0], inner_pts[0], inner_pts[2]], fill=highlight_color, outline=(255,255,255,100), width=1)
        draw.polygon(inner_pts, fill=base_color, outline=(255, 255, 255, 220), width=2)

    elif shape_type == "amethyst":
        # Teardrop / Pear cut
        outer_pts = [(64, 12), (106, 54), (96, 98), (64, 114), (32, 98), (22, 54)]
        inner_pts = [(64, 36), (88, 62), (80, 88), (64, 98), (48, 88), (40, 62)]
        draw.polygon(outer_pts, fill=base_color, outline=(255, 255, 255, 180), width=2)
        for i in range(6):
            p1 = outer_pts[i]
            p2 = outer_pts[(i+1)%6]
            p3 = inner_pts[(i+1)%6]
            p4 = inner_pts[i]
            c = highlight_color if i in [0, 5] else (dark_color if i in [2, 3] else base_color)
            draw.polygon([p1, p2, p3, p4], fill=c, outline=(255, 255, 255, 100), width=1)
        draw.polygon(inner_pts, fill=highlight_color, outline=(255, 255, 255, 210), width=2)

    # Specular Glint (star sparkle on top left)
    glint_x, glint_y = 44, 40
    for r in range(6, 0, -1):
        alpha = int(255 * (1.0 - r / 6.0))
        draw.ellipse([glint_x - r, glint_y - r, glint_x + r, glint_y + r], fill=(255, 255, 255, alpha))
    draw.line([(glint_x - 10, glint_y), (glint_x + 10, glint_y)], fill=(255, 255, 255, 220), width=2)
    draw.line([(glint_x, glint_y - 10), (glint_x, glint_y + 10)], fill=(255, 255, 255, 220), width=2)

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename, "PNG")
    print(f"Saved: {filename}")


def draw_star(filename, filled=True):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pts = []
    for i in range(10):
        r = 52 if i % 2 == 0 else 24
        ang = i * math.pi / 5.0 - math.pi / 2.0
        pts.append((64 + r * math.cos(ang), 64 + r * math.sin(ang)))
    
    if filled:
        # Gold gradient star
        draw.polygon(pts, fill=(255, 215, 0, 255), outline=(255, 245, 180, 255), width=3)
        # Inner highlight
        inner_pts = []
        for i in range(10):
            r = 38 if i % 2 == 0 else 16
            ang = i * math.pi / 5.0 - math.pi / 2.0
            inner_pts.append((64 + r * math.cos(ang), 64 + r * math.sin(ang)))
        draw.polygon(inner_pts, fill=(255, 235, 100, 255))
    else:
        # Dark translucent empty star outline
        draw.polygon(pts, fill=(40, 40, 70, 180), outline=(130, 130, 180, 200), width=3)
        
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename, "PNG")
    print(f"Saved: {filename}")


def draw_level_node(filename, state="unlocked"):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Outer drop shadow
    shadow_img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_img)
    sdraw.ellipse([14, 18, 114, 118], fill=(0, 0, 0, 120))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(5))
    img.paste(shadow_img, (0, 0), shadow_img)

    if state == "locked":
        # Grey stony circle
        draw.ellipse([18, 18, 110, 110], fill=(80, 80, 100, 255), outline=(120, 120, 140, 255), width=4)
        draw.ellipse([26, 26, 102, 102], fill=(60, 60, 80, 255))
        # Lock icon
        draw.arc([52, 42, 76, 68], start=180, end=0, fill=(200, 200, 220, 255), width=5)
        draw.rounded_rectangle([48, 58, 80, 84], radius=4, fill=(200, 200, 220, 255))
        draw.ellipse([61, 66, 67, 72], fill=(60, 60, 80, 255))
    elif state == "completed":
        # Glowing Teal/Emerald circle with gold rim
        draw.ellipse([16, 16, 112, 112], fill=(0, 200, 150, 255), outline=(255, 215, 0, 255), width=5)
        draw.ellipse([24, 24, 104, 104], fill=(0, 160, 120, 255))
    elif state == "current":
        # Bright vibrant Indigo / Purple with pulsating golden glow rim
        draw.ellipse([14, 14, 114, 114], fill=(255, 215, 0, 160), outline=(255, 235, 100, 255), width=4)
        draw.ellipse([20, 20, 108, 108], fill=(130, 70, 240, 255), outline=(255, 255, 255, 255), width=4)
        draw.ellipse([26, 26, 102, 102], fill=(100, 45, 210, 255))
    else: # unlocked
        draw.ellipse([18, 18, 110, 110], fill=(70, 130, 240, 255), outline=(150, 200, 255, 255), width=4)
        draw.ellipse([26, 26, 102, 102], fill=(45, 95, 200, 255))

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    img.save(filename, "PNG")
    print(f"Saved: {filename}")


def main():
    base_pieces = "assets/graphics/pieces"
    base_ui = "assets/graphics/ui"

    # Gems
    draw_faceted_gem(f"{base_pieces}/gem_diamond.png", (0, 200, 255, 255), (150, 240, 255, 255), (0, 130, 190, 255), "diamond")
    draw_faceted_gem(f"{base_pieces}/gem_ruby.png", (230, 30, 70, 255), (255, 110, 140, 255), (150, 15, 45, 255), "ruby")
    draw_faceted_gem(f"{base_pieces}/gem_emerald.png", (0, 210, 100, 255), (120, 255, 170, 255), (0, 130, 60, 255), "emerald")
    draw_faceted_gem(f"{base_pieces}/gem_sapphire.png", (35, 100, 245, 255), (120, 170, 255, 255), (15, 55, 160, 255), "sapphire")
    draw_faceted_gem(f"{base_pieces}/gem_topaz.png", (255, 185, 0, 255), (255, 230, 110, 255), (180, 110, 0, 255), "topaz")
    draw_faceted_gem(f"{base_pieces}/gem_amethyst.png", (180, 40, 230, 255), (230, 130, 255, 255), (110, 15, 155, 255), "amethyst")

    # UI Icons
    draw_star(f"{base_ui}/star_filled.png", filled=True)
    draw_star(f"{base_ui}/star_empty.png", filled=False)
    
    # Level Map Node states
    draw_level_node(f"{base_ui}/node_locked.png", "locked")
    draw_level_node(f"{base_ui}/node_unlocked.png", "unlocked")
    draw_level_node(f"{base_ui}/node_current.png", "current")
    draw_level_node(f"{base_ui}/node_completed.png", "completed")

    print("All textures created successfully!")

if __name__ == "__main__":
    main()
