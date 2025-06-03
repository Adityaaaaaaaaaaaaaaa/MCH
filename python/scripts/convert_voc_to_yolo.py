import os
import xml.etree.ElementTree as ET

# === EDIT THESE PATHS ===
xml_dir = "python/voc_annotations"
output_dir = "python/yolo_labels"
classes_path = "python/classes.txt"
# ========================

# Load classes
with open(classes_path, "r") as f:
    classes = [line.strip() for line in f.readlines()]

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

def convert_box(size, box):
    dw = 1.0 / size[0]
    dh = 1.0 / size[1]
    x = (box[0] + box[1]) / 2.0
    y = (box[2] + box[3]) / 2.0
    w = box[1] - box[0]
    h = box[3] - box[2]
    x = x * dw
    w = w * dw
    y = y * dh
    h = h * dh
    return (x, y, w, h)

for xml_file in os.listdir(xml_dir):
    if not xml_file.endswith('.xml'):
        continue
    tree = ET.parse(os.path.join(xml_dir, xml_file))
    root = tree.getroot()

    size = root.find('size')
    w = int(size.find('width').text)
    h = int(size.find('height').text)

    label_lines = []
    for obj in root.findall('object'):
        cls = obj.find('name').text
        if cls not in classes:
            continue
        cls_id = classes.index(cls)
        xml_box = obj.find('bndbox')
        b = (
            float(xml_box.find('xmin').text),
            float(xml_box.find('xmax').text),
            float(xml_box.find('ymin').text),
            float(xml_box.find('ymax').text)
        )
        bb = convert_box((w, h), b)
        label_lines.append(f"{cls_id} {bb[0]:.6f} {bb[1]:.6f} {bb[2]:.6f} {bb[3]:.6f}")

    # Save label file (same basename, .txt)
    label_filename = os.path.splitext(xml_file)[0] + ".txt"
    with open(os.path.join(output_dir, label_filename), "w") as out_f:
        out_f.write("\n".join(label_lines))
