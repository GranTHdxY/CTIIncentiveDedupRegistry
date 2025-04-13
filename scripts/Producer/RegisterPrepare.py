import json
import time
import threading
from simhash import Simhash

# ========== 雪花ID生成部分 ==========
machine_id = 1
sequence = 0
last_timestamp = -1
epoch = 1609459200000

def current_millis():
    return int(time.time() * 1000)

def generate_id():
    global sequence, last_timestamp
    timestamp = current_millis()
    if timestamp == last_timestamp:
        sequence = (sequence + 1) & 0xFFF
        if sequence == 0:
            while timestamp <= last_timestamp:
                timestamp = current_millis()
    else:
        sequence = 0
    last_timestamp = timestamp
    return ((timestamp - epoch) << 22) | (machine_id << 12) | sequence

# ========== SimHash 计算部分 ==========
def read_json_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)

def extract_all_fields(data):
    result = []
    if isinstance(data, dict):
        for key, value in data.items():
            result.append(f"{key}: {extract_all_fields(value)}")
    elif isinstance(data, list):
        for item in data:
            result.append(extract_all_fields(item))
    else:
        return str(data)
    return " | ".join(result)

def extract_intelligence_features(json_data):
    intelligence_data = json_data['data'][0]['intelligence'][0]
    return extract_all_fields(intelligence_data)

def compute_simhash(text):
    return Simhash(text)

# ========== 标签字段路径提取部分 ==========
results = []

def extract_keys(obj, prefix=''):
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_prefix = f"{prefix}.{k}" if prefix else k
            extract_keys(v, new_prefix)
    elif isinstance(obj, list):
        for item in obj:
            extract_keys(item, prefix)
    else:
        results.append(prefix)

# ========== 主程序 ==========
if __name__ == "__main__":
    json_path = 'Threatbookdata\Threatbook_data_1.json'  # 请确保路径正确

    # 加载数据
    data = read_json_file(json_path)

    # ✅ 提取 tip（data 中的 ioc 字段）
    tip = data["data"][0]["ioc"]
    print(f"通过ioc提取出的Tip为: {tip}")

    # 提取 tags 字段路径
    extract_keys(data["data"][0])
    formatted_tags = list(results)
    print("字段路径 tags (JSON 格式):")
    print(json.dumps(formatted_tags, ensure_ascii=False))

    # 计算 SimHash
    text = extract_intelligence_features(data)
    simhash_value = compute_simhash(text)
    print(f"生成的cti_hash值为: {simhash_value.value}")

    # 生成唯一ID
    uid = generate_id()
    print(f"生成的唯一tid为: {uid}")
