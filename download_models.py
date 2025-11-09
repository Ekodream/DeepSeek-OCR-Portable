"""
DeepSeek-OCR Model Downloader
从 ModelScope 下载 DeepSeek-OCR 模型文件到 ./models 目录
"""

import os
import sys
import requests
from pathlib import Path
from tqdm import tqdm
import json
import time

# ModelScope API 基础 URL
MODELSCOPE_API = "https://www.modelscope.cn/api/v1/models/deepseek-ai/DeepSeek-OCR/repo/files"
MODEL_FILES_URL = "https://www.modelscope.cn/models/deepseek-ai/DeepSeek-OCR/files"

# 需要下载的文件列表（根据 DeepSeek-OCR 项目的典型结构）
REQUIRED_FILES = [
    "config.json",
    "configuration.json", 
    "preprocessor_config.json",
    "tokenizer_config.json",
    "tokenizer.json",
    "special_tokens_map.json",
    "vocab.json",
    "merges.txt",
    "model.safetensors",
    "pytorch_model.bin",
]

def get_file_list():
    """从 ModelScope API 获取文件列表"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        # 尝试通过 API 获取文件列表
        response = requests.get(MODELSCOPE_API, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            if 'Data' in data and isinstance(data['Data'], list):
                return [item['Path'] for item in data['Data'] if 'Path' in item]
        
        print(f"⚠️  无法通过 API 获取文件列表 (状态码: {response.status_code})")
        print("   将使用预定义的文件列表...")
        return REQUIRED_FILES
        
    except Exception as e:
        print(f"⚠️  获取文件列表时出错: {e}")
        print("   将使用预定义的文件列表...")
        return REQUIRED_FILES


def download_file(url, destination, max_retries=3):
    """下载单个文件，支持断点续传和重试"""
    
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    # 检查本地文件
    resume_header = {}
    initial_pos = 0
    if destination.exists():
        initial_pos = destination.stat().st_size
        resume_header = {'Range': f'bytes={initial_pos}-'}
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, headers={**headers, **resume_header}, 
                                   stream=True, timeout=30)
            
            # 如果服务器不支持断点续传，从头开始
            if response.status_code == 416 or (response.status_code == 200 and initial_pos > 0):
                initial_pos = 0
                response = requests.get(url, headers=headers, stream=True, timeout=30)
            
            if response.status_code not in [200, 206]:
                raise Exception(f"HTTP {response.status_code}")
            
            total_size = int(response.headers.get('content-length', 0)) + initial_pos
            
            mode = 'ab' if initial_pos > 0 and response.status_code == 206 else 'wb'
            
            with open(destination, mode) as f:
                with tqdm(total=total_size, initial=initial_pos, 
                         unit='B', unit_scale=True, 
                         desc=destination.name) as pbar:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            pbar.update(len(chunk))
            
            # 验证文件完整性
            if total_size > 0 and destination.stat().st_size != total_size:
                raise Exception("文件大小不匹配")
            
            return True
            
        except Exception as e:
            print(f"\n⚠️  下载失败 (尝试 {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f"   等待 {wait_time} 秒后重试...")
                time.sleep(wait_time)
            else:
                print(f"❌ 下载 {destination.name} 失败")
                return False
    
    return False


def download_models():
    """下载所有模型文件"""
    
    models_dir = Path("./models")
    models_dir.mkdir(exist_ok=True)
    
    print("=" * 60)
    print("DeepSeek-OCR 模型下载器")
    print("=" * 60)
    print(f"目标目录: {models_dir.absolute()}\n")
    
    # 获取文件列表
    print("📋 获取文件列表...")
    file_list = get_file_list()
    print(f"✓ 找到 {len(file_list)} 个文件\n")
    
    # 下载文件
    success_count = 0
    failed_files = []
    
    for filename in file_list:
        # 构建下载 URL (ModelScope CDN)
        download_url = f"https://www.modelscope.cn/api/v1/models/deepseek-ai/DeepSeek-OCR/repo?Revision=master&FilePath={filename}"
        
        destination = models_dir / filename
        
        # 检查文件是否已存在
        if destination.exists():
            print(f"✓ {filename} 已存在，跳过")
            success_count += 1
            continue
        
        print(f"\n📥 下载: {filename}")
        if download_file(download_url, destination):
            print(f"✓ 完成: {filename}")
            success_count += 1
        else:
            failed_files.append(filename)
    
    # 总结
    print("\n" + "=" * 60)
    print(f"下载完成: {success_count}/{len(file_list)} 个文件")
    
    if failed_files:
        print(f"\n❌ 以下文件下载失败:")
        for f in failed_files:
            print(f"   - {f}")
        print("\n💡 提示: 您可以:")
        print("   1. 重新运行此脚本继续下载")
        print(f"   2. 手动访问 {MODEL_FILES_URL} 下载")
        return False
    else:
        print("\n✅ 所有文件下载成功!")
        return True


if __name__ == "__main__":
    try:
        success = download_models()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  下载已取消")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
