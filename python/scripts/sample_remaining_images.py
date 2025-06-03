import random

# Desired total dataset size
TARGET_TOTAL = 30000

with open("python/image_list.txt", "r") as f:
    all_images = [line.strip() for line in f]

with open("python/already_downloaded.txt", "r") as f:
    already_downloaded = set(line.strip() for line in f)

# Filter out already downloaded
remaining_images = [img for img in all_images if img.split('/')[1] not in already_downloaded]

# How many more do we need?
need = max(0, TARGET_TOTAL - len(already_downloaded))
sampled = random.sample(remaining_images, min(need, len(remaining_images)))

# Combine already downloaded with the new sample (in the same format)
with open("python/image_list_final.txt", "w") as f:
    # Already downloaded (format: train/IMAGEID)
    for img_id in already_downloaded:
        f.write(f"train/{img_id}\n")
    # Sampled remaining
    for img in sampled:
        f.write(img + "\n")

print(f"Final list: {len(already_downloaded)} already downloaded, {len(sampled)} to download. Total: {len(already_downloaded) + len(sampled)}")
