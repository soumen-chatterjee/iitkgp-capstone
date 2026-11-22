#!/bin/bash
#SBATCH --job-name=test_gpu
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00
#SBATCH --output=logs/test_gpu-%j.out
#SBATCH --error=logs/test_gpu-%j.err

source /storage/tracka/users/learner04/project/iitkgp-capstone/.venv/bin/activate

echo "=== nvidia-smi ==="
nvidia-smi

echo "=== PyTorch CUDA Check ==="
python -c "
import torch
print('PyTorch:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
assert torch.cuda.is_available(), 'CUDA is not available!'
print('Device count:', torch.cuda.device_count())
print('Device name:', torch.cuda.get_device_name(0))
free, total = torch.cuda.mem_get_info(0)
print(f'VRAM: {free/2**30:.1f} GiB free / {total/2**30:.1f} GiB total')
x = torch.randn((1024, 1024), device='cuda')
print('Matrix multiply test OK:', (x @ x).mean().item())
"
