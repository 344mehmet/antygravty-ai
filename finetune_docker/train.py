"""
LLM Fine-tuning Script with Unsloth (GPU)
344Mehmet LLM Ordusu için QLoRA fine-tuning
"""

import os
import json
from datasets import Dataset
from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments

# Configuration from environment
MODEL_NAME = os.getenv("MODEL_NAME", "unsloth/Phi-3-mini-4k-instruct")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "/app/output")
TRAIN_DATA = os.getenv("TRAIN_DATA", "/app/data/training_data.jsonl")
MAX_STEPS = int(os.getenv("MAX_STEPS", "100"))
LEARNING_RATE = float(os.getenv("LEARNING_RATE", "2e-4"))
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "2"))
MAX_SEQ_LENGTH = 2048

def load_training_data(filepath: str) -> Dataset:
    """JSONL formatındaki eğitim verisini yükle"""
    data = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                item = json.loads(line)
                # Convert to instruction format
                messages = item.get("messages", [])
                if len(messages) >= 2:
                    system = ""
                    user = ""
                    assistant = ""
                    for msg in messages:
                        role = msg.get("role", "")
                        content = msg.get("content", "")
                        if role == "system":
                            system = content
                        elif role == "user":
                            user = content
                        elif role == "assistant":
                            assistant = content
                    
                    # Format as instruction
                    instruction = f"{system}\n\nKullanıcı: {user}" if system else user
                    data.append({
                        "instruction": instruction,
                        "output": assistant
                    })
    
    return Dataset.from_list(data)

def format_prompts(examples):
    """Prompt format for training"""
    instructions = examples["instruction"]
    outputs = examples["output"]
    
    texts = []
    for instruction, output in zip(instructions, outputs):
        text = f"""### Talimat:
{instruction}

### Cevap:
{output}"""
        texts.append(text)
    
    return {"text": texts}

def main():
    print(f"🚀 Fine-tuning başlatılıyor...")
    print(f"   Model: {MODEL_NAME}")
    print(f"   Veri: {TRAIN_DATA}")
    print(f"   Max Steps: {MAX_STEPS}")
    
    # Load model with Unsloth (4-bit quantization)
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=MODEL_NAME,
        max_seq_length=MAX_SEQ_LENGTH,
        dtype=None,  # Auto-detect
        load_in_4bit=True,
    )
    
    # Apply LoRA
    model = FastLanguageModel.get_peft_model(
        model,
        r=16,  # LoRA rank
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                       "gate_proj", "up_proj", "down_proj"],
        lora_alpha=16,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=42,
    )
    
    # Load and format dataset
    dataset = load_training_data(TRAIN_DATA)
    dataset = dataset.map(format_prompts, batched=True)
    
    print(f"📊 Eğitim verisi: {len(dataset)} örnek")
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir=OUTPUT_DIR,
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=4,
        warmup_steps=5,
        max_steps=MAX_STEPS,
        learning_rate=LEARNING_RATE,
        fp16=True,
        logging_steps=10,
        save_steps=50,
        save_total_limit=2,
        optim="adamw_8bit",
    )
    
    # Initialize trainer
    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        dataset_text_field="text",
        max_seq_length=MAX_SEQ_LENGTH,
        args=training_args,
    )
    
    # Train
    print("🎯 Eğitim başlıyor...")
    trainer.train()
    
    # Save model
    print(f"💾 Model kaydediliyor: {OUTPUT_DIR}")
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    
    # Save in GGUF format for Ollama
    print("📦 GGUF formatına dönüştürülüyor (Ollama için)...")
    model.save_pretrained_gguf(
        f"{OUTPUT_DIR}/gguf",
        tokenizer,
        quantization_method="q4_k_m"
    )
    
    print("✅ Fine-tuning tamamlandı!")
    print(f"   Model: {OUTPUT_DIR}")
    print(f"   GGUF: {OUTPUT_DIR}/gguf")

if __name__ == "__main__":
    main()
