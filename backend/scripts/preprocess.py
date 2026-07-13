import os
import json
import re
from sklearn.model_selection import train_test_split

def clean_text(text: str) -> str:
    if not text:
        return ""
    # Remove HTML tags
    text = re.sub(r"<[^>]*>", "", text)
    # Remove extra spaces
    text = re.sub(r"\s+", " ", text).strip()
    return text

def preprocess_dataset(raw_dir: str, processed_dir: str, dataset_name: str, text_key: str):
    print(f"Preprocessing {dataset_name}...")
    raw_path = os.path.join(raw_dir, dataset_name)
    out_dir = os.path.join(processed_dir, dataset_name)
    os.makedirs(out_dir, exist_ok=True)
    
    if not os.path.exists(raw_path):
        print(f"Raw directory not found: {raw_path}")
        return

    # Collect all lines/utterances from files
    all_data = []
    seen = set()
    
    for file_name in os.listdir(raw_path):
        if not file_name.endswith(".jsonl"):
            continue
        full_path = os.path.join(raw_path, file_name)
        with open(full_path, "r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                    # Extract the text depending on the dataset structure
                    text_val = record.get(text_key, "")
                    if isinstance(text_val, list):
                        text_val = " ".join([str(t) for t in text_val])
                    
                    cleaned = clean_text(str(text_val))
                    if not cleaned:
                        continue
                    
                    if cleaned not in seen:
                        seen.add(cleaned)
                        record["cleaned_text"] = cleaned
                        all_data.append(record)
                except Exception as e:
                    pass
                    
    if not all_data:
        print(f"No data found for {dataset_name}")
        return
        
    # Split: 80% train, 10% val, 10% test
    # Handle cases where placeholder data may be very small
    if len(all_data) < 5:
        # Use all data for training, leave validation and test empty
        train_data = all_data
        val_data = []
        test_data = []
    else:
        train_data, val_test = train_test_split(all_data, test_size=0.2, random_state=42)
        val_data, test_data = train_test_split(val_test, test_size=0.5, random_state=42)

    splits = {"train": train_data, "val": val_data, "test": test_data}
    for split_name, split_list in splits.items():
        split_path = os.path.join(out_dir, f"{split_name}.jsonl")
        with open(split_path, "w", encoding="utf-8") as f:
            for item in split_list:
                json.dump(item, f)
                f.write("\n")
                
    print(f"Preprocessed {dataset_name}: {len(train_data)} train, {len(val_data)} val, {len(test_data)} test saved to {out_dir}")

def main():
    raw_dir = "datasets/raw"
    processed_dir = "datasets/processed"
    
    # Map dataset name to the key that contains the main text/dialogue in raw jsonl
    dataset_configs = [
        {"name": "goemotions", "key": "text"},
        {"name": "dailydialog", "key": "dialogue"},
        {"name": "personachat", "key": "history"},
        {"name": "emotionlines", "key": "utterance"},
        {"name": "cornell", "key": "utterances"}
    ]
    
    for config in dataset_configs:
        preprocess_dataset(raw_dir, processed_dir, config["name"], config["key"])

if __name__ == "__main__":
    main()
