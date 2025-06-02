import os
import pandas as pd
from lxml import etree

# === Paths ===
IMAGE_LIST = "python/image_list_final.txt"
ANNOT_CSV = "python/oidv6-train-annotations-bbox.csv"
CLASS_CSV = "python/oidv7-class-descriptions-boxable.csv"
IMG_DIR = "python/downloaded_images"
VOC_ANN_DIR = "python/voc_annotations"

# === Create output dir if it does not exist ===
os.makedirs(VOC_ANN_DIR, exist_ok=True)

# === Load image list and class mapping ===
with open(IMAGE_LIST, "r") as f:
    image_ids = set([line.strip().split("/")[1] for line in f])

class_map = pd.read_csv(CLASS_CSV, header=None, names=["LabelName", "ClassName"])
class_map = dict(zip(class_map.LabelName, class_map.ClassName))

# === Load and filter annotations ===
print("Reading annotation CSV...")
annots = pd.read_csv(ANNOT_CSV)
filtered_annots = annots[annots['ImageID'].isin(image_ids)]

# Group by image
grouped = filtered_annots.groupby("ImageID")

def make_voc_xml(image_id, objects, width=1024, height=768, depth=3):
    annotation = etree.Element("annotation")
    etree.SubElement(annotation, "folder").text = "VOC"
    etree.SubElement(annotation, "filename").text = image_id + ".jpg"
    size = etree.SubElement(annotation, "size")
    etree.SubElement(size, "width").text = str(width)
    etree.SubElement(size, "height").text = str(height)
    etree.SubElement(size, "depth").text = str(depth)
    etree.SubElement(annotation, "segmented").text = "0"
    for _, row in objects.iterrows():
        obj = etree.SubElement(annotation, "object")
        class_name = class_map.get(row.LabelName, "unknown")
        etree.SubElement(obj, "name").text = class_name
        etree.SubElement(obj, "pose").text = "Unspecified"
        etree.SubElement(obj, "truncated").text = str(int(row.IsTruncated))
        etree.SubElement(obj, "difficult").text = "0"
        bndbox = etree.SubElement(obj, "bndbox")
        xmin = int(float(row.XMin) * width)
        ymin = int(float(row.YMin) * height)
        xmax = int(float(row.XMax) * width)
        ymax = int(float(row.YMax) * height)
        etree.SubElement(bndbox, "xmin").text = str(xmin)
        etree.SubElement(bndbox, "ymin").text = str(ymin)
        etree.SubElement(bndbox, "xmax").text = str(xmax)
        etree.SubElement(bndbox, "ymax").text = str(ymax)
    return etree.tostring(annotation, pretty_print=True)

print(f"Writing Pascal VOC XMLs to {VOC_ANN_DIR}...")
count = 0
for image_id, objects in grouped:
    xml = make_voc_xml(image_id, objects)
    with open(os.path.join(VOC_ANN_DIR, image_id + ".xml"), "wb") as f:
        f.write(xml)
    count += 1
    if count % 1000 == 0:
        print(f"Processed {count} images...")

print(f"Finished! Wrote {count} annotation XML files.")
