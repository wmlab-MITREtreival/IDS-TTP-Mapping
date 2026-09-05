import os
import random
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.model_selection import train_test_split
from sklearn.utils.class_weight import compute_class_weight
from torch.utils.data import DataLoader, Dataset
from tqdm import tqdm
from transformers import AutoModel, AutoTokenizer, get_linear_schedule_with_warmup


def set_seed(seed: int = 42) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


set_seed(42)

CSV_PATH = 'final_labeled_ids_logs.csv'
OUTPUT_DIR = Path('saved_model')
PREDICTION_CSV = 'classification_predictions.csv'
MAX_LEN = 160
BATCH_SIZE = 8
EPOCHS = 5
LR = 2e-5
PATIENCE = 2
TRAIN_REMOTE = os.getenv('ALLOW_REMOTE_MODEL_DOWNLOAD', '0') == '1'
SECUREBERT_LOCAL_DIR = os.getenv('SECUREBERT_LOCAL_DIR', '').strip()
SECUREBERT_MODEL_NAME = os.getenv('SECUREBERT_MODEL_NAME', 'ehsanaghaei/SecureBERT').strip()
HF_REVISION = os.getenv('HF_REVISION', None)

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

COLUMN_MAP = {
    'Alert_ID': 'alert_id',
    'Timestamp': 'timestamp',
    'Source_IP': 'src_ip',
    'Destination_IP': 'dest_ip',
    'Port': 'dest_port',
    'Protocol': 'proto',
    'Alert_Signature': 'alert.signature',
    'Alert_Category': 'alert.category',
    'Subsystem_Type': 'subsystem_type',
    'Severity': 'alert.severity',
    'Event_Type': 'event_type',
    'Flow_ID': 'flow_id',
    'Payload_Length': 'payload_length',
    'HTTP_URI': 'http.uri',
    'Process_Name': 'process.name',
    'Command_Line': 'process.command_line',
    'File_Name': 'fileinfo.filename',
}


def safe_get(row: pd.Series, col_name: str, default: str = 'NA') -> str:
    return str(row[col_name]) if col_name in row.index and pd.notna(row[col_name]) else default


def extract_hour(timestamp_value: str) -> str:
    try:
        ts = pd.to_datetime(timestamp_value)
        return str(ts.hour)
    except Exception:
        return 'NA'


def normalize_ip(ip_value: str) -> str:
    if ip_value in {'NA', '', 'nan', 'None'}:
        return 'NA'
    if ip_value.startswith('192.168.') or ip_value.startswith('10.') or ip_value.startswith('172.'):
        return 'internal_ip'
    return 'external_ip'


def compute_payload_length(row: pd.Series) -> str:
    payload_col = COLUMN_MAP['Payload_Length']
    if payload_col in row.index and pd.notna(row[payload_col]):
        return str(row[payload_col])
    if 'payload' in row.index and pd.notna(row['payload']):
        return str(len(str(row['payload'])))
    return 'NA'


def build_text_features(row: pd.Series) -> str:
    timestamp_val = safe_get(row, COLUMN_MAP['Timestamp'])
    source_ip = normalize_ip(safe_get(row, COLUMN_MAP['Source_IP']))
    dest_ip = normalize_ip(safe_get(row, COLUMN_MAP['Destination_IP']))
    port = safe_get(row, COLUMN_MAP['Port'])
    protocol = safe_get(row, COLUMN_MAP['Protocol'])
    alert_signature = safe_get(row, COLUMN_MAP['Alert_Signature'])
    alert_category = safe_get(row, COLUMN_MAP['Alert_Category'])
    subsystem_type = safe_get(row, COLUMN_MAP['Subsystem_Type'])
    severity = safe_get(row, COLUMN_MAP['Severity'])
    event_type = safe_get(row, COLUMN_MAP['Event_Type'])
    flow_id = safe_get(row, COLUMN_MAP['Flow_ID'])
    payload_length = compute_payload_length(row)
    http_uri = safe_get(row, COLUMN_MAP['HTTP_URI'])
    process_name = safe_get(row, COLUMN_MAP['Process_Name'])
    command_line = safe_get(row, COLUMN_MAP['Command_Line'])
    file_name = safe_get(row, COLUMN_MAP['File_Name'])
    hour_of_day = extract_hour(timestamp_val)

    # NOTE: alert_id intentionally excluded from model input to avoid leakage.
    text = (
        f"Timestamp {timestamp_val} | Hour {hour_of_day} | Source_IP {source_ip} | "
        f"Destination_IP {dest_ip} | Port {port} | Protocol {protocol} | "
        f"Alert_Signature {alert_signature} | Alert_Category {alert_category} | "
        f"Subsystem_Type {subsystem_type} | Severity {severity} | Event_Type {event_type} | "
        f"Flow_ID {flow_id} | Payload_Length {payload_length} | HTTP_URI {http_uri} | "
        f"Process_Name {process_name} | Command_Line {command_line} | File_Name {file_name}"
    )
    return text


class AlertDataset(Dataset):
    def __init__(self, texts: Sequence[str], labels: Sequence[int], tokenizer, max_len: int):
        self.texts = list(texts)
        self.labels = list(labels)
        self.tokenizer = tokenizer
        self.max_len = max_len

    def __len__(self) -> int:
        return len(self.labels)

    def __getitem__(self, idx: int) -> Dict[str, torch.Tensor]:
        encoding = self.tokenizer(
            self.texts[idx],
            truncation=True,
            padding='max_length',
            max_length=self.max_len,
            return_tensors='pt',
        )
        return {
            'input_ids': encoding['input_ids'].squeeze(0),
            'attention_mask': encoding['attention_mask'].squeeze(0),
            'labels': torch.tensor(self.labels[idx], dtype=torch.long),
        }


class SecureBERTBiLSTM(nn.Module):
    def __init__(self, model_name: str, hidden_dim: int = 128, num_classes: int = 2, dropout: float = 0.3, local_files_only: bool = True, revision: Optional[str] = None):
        super().__init__()
        model_kwargs = {'local_files_only': local_files_only}
        if revision:
            model_kwargs['revision'] = revision
        self.bert = AutoModel.from_pretrained(model_name, **model_kwargs)
        self.lstm = nn.LSTM(
            input_size=self.bert.config.hidden_size,
            hidden_size=hidden_dim,
            batch_first=True,
            bidirectional=True,
        )
        self.dropout = nn.Dropout(dropout)
        self.classifier = nn.Linear(hidden_dim * 2, num_classes)

    @staticmethod
    def masked_mean_pooling(token_embeddings: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        mask = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        masked_embeddings = token_embeddings * mask
        summed = masked_embeddings.sum(dim=1)
        counts = mask.sum(dim=1).clamp(min=1e-9)
        return summed / counts

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        outputs = self.bert(input_ids=input_ids, attention_mask=attention_mask)
        sequence_output = outputs.last_hidden_state
        lstm_out, _ = self.lstm(sequence_output)
        pooled = self.masked_mean_pooling(lstm_out, attention_mask)
        pooled = self.dropout(pooled)
        return self.classifier(pooled)


def load_tokenizer_and_model() -> Tuple[str, AutoTokenizer, SecureBERTBiLSTM]:
    candidates: List[Tuple[str, bool]] = []
    if SECUREBERT_LOCAL_DIR:
        candidates.append((SECUREBERT_LOCAL_DIR, True))
    if SECUREBERT_MODEL_NAME:
        candidates.append((SECUREBERT_MODEL_NAME, not TRAIN_REMOTE))
    candidates.append(('bert-base-uncased', not TRAIN_REMOTE))

    errors = []
    for model_name, local_only in candidates:
        try:
            tokenizer = AutoTokenizer.from_pretrained(model_name, local_files_only=local_only, revision=HF_REVISION)
            model = SecureBERTBiLSTM(model_name, local_files_only=local_only, revision=HF_REVISION).to(DEVICE)
            print(f"[OK] Loaded model: {model_name} (local_only={local_only})")
            return model_name, tokenizer, model
        except Exception as exc:
            errors.append(f"{model_name}: {exc}")

    raise RuntimeError('Unable to load SecureBERT/BERT model. Tried:\n' + '\n'.join(errors))


def evaluate(model: nn.Module, loader: DataLoader, loss_fn) -> Tuple[float, float, float, List[int], List[int], List[float]]:
    model.eval()
    total_loss = 0.0
    all_preds: List[int] = []
    all_labels: List[int] = []
    all_scores: List[float] = []

    with torch.no_grad():
        for batch in loader:
            input_ids = batch['input_ids'].to(DEVICE)
            attention_mask = batch['attention_mask'].to(DEVICE)
            labels = batch['labels'].to(DEVICE)

            logits = model(input_ids, attention_mask)
            loss = loss_fn(logits, labels)
            total_loss += loss.item()

            probs = torch.softmax(logits, dim=1)[:, 1]
            preds = torch.argmax(logits, dim=1)

            all_preds.extend(preds.cpu().numpy().tolist())
            all_labels.extend(labels.cpu().numpy().tolist())
            all_scores.extend(probs.cpu().numpy().tolist())

    avg_loss = total_loss / max(1, len(loader))
    f1 = f1_score(all_labels, all_preds, average='weighted')
    acc = accuracy_score(all_labels, all_preds)
    return avg_loss, f1, acc, all_labels, all_preds, all_scores


def predict_all(df_all: pd.DataFrame, tokenizer, model: nn.Module) -> pd.DataFrame:
    dataset = AlertDataset(df_all['text'].tolist(), df_all['final_label'].tolist(), tokenizer, MAX_LEN)
    loader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=False)

    model.eval()
    preds_all: List[int] = []
    scores_all: List[float] = []
    with torch.no_grad():
        for batch in tqdm(loader, desc='Predicting full dataset'):
            input_ids = batch['input_ids'].to(DEVICE)
            attention_mask = batch['attention_mask'].to(DEVICE)
            logits = model(input_ids, attention_mask)
            probs = torch.softmax(logits, dim=1)[:, 1]
            preds = torch.argmax(logits, dim=1)
            preds_all.extend(preds.cpu().numpy().tolist())
            scores_all.extend(probs.cpu().numpy().tolist())

    out = df_all.copy()
    out['predicted_label'] = preds_all
    out['confidence_score'] = scores_all
    return out


def main() -> None:
    if not Path(CSV_PATH).exists():
        raise FileNotFoundError(f'{CSV_PATH} not found.')

    df = pd.read_csv(CSV_PATH)
    if 'final_label' not in df.columns:
        raise ValueError("Missing required column 'final_label'.")

    df = df[df['final_label'].isin([0, 1])].copy()
    df['text'] = df.apply(build_text_features, axis=1)
    keep_cols = ['text', 'final_label']
    for key in ['Alert_ID', 'Timestamp', 'Source_IP', 'Destination_IP', 'Alert_Signature', 'Alert_Category']:
        mapped = COLUMN_MAP[key]
        if mapped in df.columns:
            keep_cols.append(mapped)

    df = df[keep_cols].dropna(subset=['text', 'final_label'])
    df = df[df['text'].str.strip() != '']

    model_name, tokenizer, model = load_tokenizer_and_model()

    texts = df['text'].tolist()
    labels = df['final_label'].tolist()
    train_texts, test_texts, train_labels, test_labels = train_test_split(
        texts, labels, test_size=0.2, stratify=labels, random_state=42
    )
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        train_texts, train_labels, test_size=0.125, stratify=train_labels, random_state=42
    )

    train_loader = DataLoader(AlertDataset(train_texts, train_labels, tokenizer, MAX_LEN), batch_size=BATCH_SIZE, shuffle=True)
    val_loader = DataLoader(AlertDataset(val_texts, val_labels, tokenizer, MAX_LEN), batch_size=BATCH_SIZE, shuffle=False)
    test_loader = DataLoader(AlertDataset(test_texts, test_labels, tokenizer, MAX_LEN), batch_size=BATCH_SIZE, shuffle=False)

    class_weights = compute_class_weight(class_weight='balanced', classes=np.array([0, 1]), y=np.array(train_labels))
    class_weights = torch.tensor(class_weights, dtype=torch.float).to(DEVICE)

    loss_fn = nn.CrossEntropyLoss(weight=class_weights)
    optimizer = torch.optim.AdamW(model.parameters(), lr=LR)
    total_steps = len(train_loader) * EPOCHS
    scheduler = get_linear_schedule_with_warmup(
        optimizer,
        num_warmup_steps=max(1, int(0.1 * total_steps)),
        num_training_steps=total_steps,
    )

    best_val_f1 = 0.0
    patience_counter = 0

    for epoch in range(EPOCHS):
        model.train()
        total_train_loss = 0.0
        loop = tqdm(train_loader, desc=f'Epoch {epoch + 1}/{EPOCHS}')

        for batch in loop:
            optimizer.zero_grad()
            input_ids = batch['input_ids'].to(DEVICE)
            attention_mask = batch['attention_mask'].to(DEVICE)
            labels = batch['labels'].to(DEVICE)

            logits = model(input_ids, attention_mask)
            loss = loss_fn(logits, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
            scheduler.step()

            total_train_loss += loss.item()
            loop.set_postfix(loss=loss.item())

        train_loss = total_train_loss / max(1, len(train_loader))
        val_loss, val_f1, val_acc, _, _, _ = evaluate(model, val_loader, loss_fn)

        print(f"\nEpoch {epoch + 1}")
        print(f"Train Loss: {train_loss:.4f}")
        print(f"Val Loss:   {val_loss:.4f}")
        print(f"Val F1:     {val_f1:.4f}")
        print(f"Val Acc:    {val_acc:.4f}")

        if val_f1 > best_val_f1:
            best_val_f1 = val_f1
            patience_counter = 0
            torch.save(model.state_dict(), OUTPUT_DIR / 'best_model.pt')
            tokenizer.save_pretrained(OUTPUT_DIR)
            with (OUTPUT_DIR / 'model_info.txt').open('w', encoding='utf-8') as f:
                f.write(f'Loaded model: {model_name}\n')
            print('[OK] Best model saved.')
        else:
            patience_counter += 1
            if patience_counter >= PATIENCE:
                print('[INFO] Early stopping triggered.')
                break

    print('\n[INFO] Loading best model for final evaluation...')
    model.load_state_dict(torch.load(OUTPUT_DIR / 'best_model.pt', map_location=DEVICE))
    test_loss, test_f1, test_acc, all_labels, all_preds, _ = evaluate(model, test_loader, loss_fn)

    print('\nFinal Test Results')
    print(f'Test Loss: {test_loss:.4f}')
    print(f'Test Acc:  {test_acc:.4f}')
    print(f'Test F1:   {test_f1:.4f}')
    print('\nClassification Report:')
    print(classification_report(all_labels, all_preds, target_names=['Benign', 'Malicious']))

    full_predictions = predict_all(df, tokenizer, model)
    full_predictions.to_csv(PREDICTION_CSV, index=False, encoding='utf-8-sig')
    print(f'[OK] Saved full prediction output: {PREDICTION_CSV}')


if __name__ == '__main__':
    main()
