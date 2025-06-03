import os

image_folder = "python/downloaded_images/"
image_files = [f for f in os.listdir(image_folder) if f.endswith('.jpg')]
image_ids = set([os.path.splitext(f)[0] for f in image_files])

print(f"Found {len(image_ids)} already downloaded images.")
with open("python/already_downloaded.txt", "w") as f:
    for img_id in image_ids:
        f.write(img_id + "\n")
