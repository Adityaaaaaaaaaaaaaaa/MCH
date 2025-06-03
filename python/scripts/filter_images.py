import pandas as pd

# === List your ingredient classes here ===
TARGET_CLASSES = [
    "Apple",
    "Artichoke",
    "Bagel",
    "Baked goods",
    "Banana",
    "Beer",
    "Bell pepper",
    "Bread",
    "Broccoli",
    "Burrito",
    "Cabbage",
    "Cake",
    "Candy",
    "Cantaloupe",
    "Carrot",
    "Cheese",
    "Chicken",
    "Cocktail",
    "Coconut",
    "Coffee (drink)",
    "Common fig",
    "Cookie",
    "Cream",
    "Croissant",
    "Cucumber",
    "Dairy Product",
    "Dessert",
    "Doughnut",
    "Drink",
    "Duck",
    "Egg",
    "Fast food",
    "Fish",
    "Food",
    "French fries",
    "Fruit",
    "Garden Asparagus",
    "Grape",
    "Grapefruit",
    "Guacamole",
    "Hamburger",
    "Honeycomb",
    "Hot dog",
    "Ice cream",
    "Juice",
    "Lemon (plant)",
    "Lobster",
    "Mango",
    "Milk",
    "Muffin",
    "Mushroom",
    "Orange (fruit)",
    "Oyster",
    "Pancake",
    "Pasta",
    "Pastry",
    "Peach",
    "Pear",
    "Pineapple",
    "Pizza",
    "Pomegranate",
    "Popcorn",
    "Potato",
    "Pretzel",
    "Pumpkin",
    "Radish",
    "Salad",
    "Sandwich",
    "Seafood",
    "Shellfish",
    "Shrimp",
    "Snack",
    "Strawberry",
    "Submarine sandwich",
    "Sushi",
    "Taco",
    "Tart",
    "Tea",
    "Tomato",
    "Turkey",
    "Vegetable",
    "Waffle",
    "Watermelon",
    "Wine",
    "Winter melon",
    "Zucchini",
]

# === Paths based on your folder structure ===
CLASS_CSV = "python/oidv7-class-descriptions-boxable.csv" 
ANNOT_CSV = "python/oidv6-train-annotations-bbox.csv"
OUTPUT_IMAGE_LIST = "python/image_list.txt"

print("Reading class descriptions...")
classes = pd.read_csv(CLASS_CSV, header=None, names=["LabelName", "ClassName"])
target_labels = classes[classes['ClassName'].isin(TARGET_CLASSES)]['LabelName'].tolist()

print(f"Target label names ({len(target_labels)}):", target_labels)

print("Filtering annotation CSV... (this may take several minutes)")
annots = pd.read_csv(ANNOT_CSV)
filtered_annots = annots[annots['LabelName'].isin(target_labels)]

unique_image_ids = filtered_annots['ImageID'].unique()

with open(OUTPUT_IMAGE_LIST, "w") as f:
    for img_id in unique_image_ids:
        f.write(f"train/{img_id}\n")

print(f"Done! Saved {len(unique_image_ids)} image IDs to {OUTPUT_IMAGE_LIST}")
