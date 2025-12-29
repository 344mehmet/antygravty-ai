"""
CPU-only Fine-tuning Script
GPU olmayan sistemler için basitleştirilmiş eğitim
"""

import os
import json
from datasets import Dataset
from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling
)
from peft import LoraConfig, get_peft_model, TaskType

# Configuration
MODEL_NAME = os.getenv("MODEL_NAME", "microsoft/phi-2")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "/app/output")
TRAIN_DATA = os.getenv("TRAIN_DATA", "/app/data/training_data.jsonl")
MAX_STEPS = int(os.getenv("MAX_STEPS", "50"))
LEARNING_RATE = float(os.getenv("LEARNING_RATE", "2e-4"))
BATCH_SIZE = int(os.getenv("BATCH_SIZE", "1"))
MAX_LENGTH = 512

def load_training_data(filepath: str) -> Dataset:
    """JSONL formatındaki eğitim verisini yükle"""
    data = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                item = json.loads(line)
                messages = item.get("messages", [])
                if len(messages) >= 2:
                    text_parts = []
                    for msg in messages:
                        role = msg.get("role", "")
                        content = msg.get("content", "")
                        if role == "system":
                            text_parts.append(f"System: {content}")
                        elif role == "user":
                            text_parts.append(f"User: {content}")
                        elif role == "assistant":
                            text_parts.append(f"Assistant: {content}")
                    
                    data.append({"text": "\n".join(text_parts)})
    
    return Dataset.from_list(data)

def main():
    print(f"🚀 CPU Fine-tuning başlatılıyor...")
    print(f"   Model: {MODEL_NAME}")
    print(f"   Max Steps: {MAX_STEPS}")
    
    # Load tokenizer and model
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
    tokenizer.pad_token = tokenizer.eos_token
    
    model = AutoModelForCausalLM.from_pretrained(
        MODEL_NAME,
        trust_remote_code=True,
        torch_dtype="auto",
        low_cpu_mem_usage=True
    )
    
    # Apply LoRA for efficient training
    lora_config = LoraConfig(
        r=8,
        lora_alpha=16,
        target_modules=["q_proj", "v_proj"],
        lora_dropout=0.05,
        bias="none",
        task_type=TaskType.CAUSAL_LM
    )
    model = get_peft_model(model, lora_config)
    model.print_trainable_parameters()
    
    # Load dataset
    dataset = load_training_data(TRAIN_DATA)
    print(f"📊 Eğitim verisi: {len(dataset)} örnek")
    
    # Tokenize
    def tokenize(examples):
        return tokenizer(
            examples["text"],
            truncation=True,
            max_length=MAX_LENGTH,
            padding="max_length"
        )
    
    tokenized_dataset = dataset.map(tokenize, batched=True, remove_columns=["text"])
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir=OUTPUT_DIR,
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=8,
        warmup_steps=5,
        max_steps=MAX_STEPS,
        learning_rate=LEARNING_RATE,
        logging_steps=10,
        save_steps=25,
        save_total_limit=2,
        fp16=False,  # CPU mode
        optim="adamw_torch",
    )
    
    # Data collator
    data_collator = DataCollatorForLanguageModeling(tokenizer=tokenizer, mlm=False)
    
    # Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_dataset,
        data_collator=data_collator,
    )
    
    # Train
    print("🎯 Eğitim başlıyor (CPU - bu biraz zaman alabilir)...")
    trainer.train()
    
    # Save
    print(f"💾 Model kaydediliyor: {OUTPUT_DIR}")
    model.save_pretrained(OUTPUT_DIR)
    tokenizer.save_pretrained(OUTPUT_DIR)
    
    print("✅ CPU Fine-tuning tamamlandı!")

if __name__ == "__main__":
    main()
