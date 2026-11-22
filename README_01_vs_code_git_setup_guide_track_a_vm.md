# Track A Remote VM: Primary User Initial Setup & Configuration Guide

This reference document walks the **primary user** through the complete, one-time provisioning of the IIT KGP Capstone environment on `upgrad-l40s-vm03`—from extracting SSH keys and configuring **VS Code (SSH FS)** to setting up **Git/GitHub**, installing **`uv`** with **Python 3.12.14**, installing all **19 pinned ML/Python packages + Jupyter**, and verifying GPU access via Slurm.

> **Security Warning:** This document contains sensitive account references and your SSH key passphrase. Store it strictly on your local machine (or in an encrypted private vault) and **never commit or push it to GitHub**.

---

## 1. Environment Overview & Key Constraints

Before starting, keep these VM architectural constraints in mind:
* **No SSH Port Forwarding (`AllowTcpForwarding no`):** Microsoft's **Remote - SSH** extension will hang indefinitely on *"Waiting for port forwarding to be ready"*. This guide uses **SSH FS** (SFTP over port `1026`) + **VS Code's Integrated Terminal**, which is 100% reliable on this VM.
* **No Hosted Jupyter, `sudo`, or Docker:** All Python tools (`uv`, `.venv`, `jupyter`) are installed in user space (`$HOME`). Direct GPU execution from the SSH login shell is blocked; all GPU workloads must be submitted via **Slurm (`sbatch`)**.
* **Shared Base Model:** `Qwen/Qwen2.5-7B-Instruct` is pre-downloaded read-only and does **not** count against your storage quota.

### Quick Reference Table

| Setting | Value |
| :--- | :--- |
| **Server Hostname / IP** | `upgrad-l40s-vm03` / `103.42.50.41` |
| **SSH Port** | `1026` |
| **Username** | `learner04` |
| **Windows Private Key Path** | `C:\Users\Soumen\Downloads\TrackA_VM03_Group04\id_ed25519` |
| **Key Passphrase** | `2RBENPka3HLZqbJiXwU9-qC1I7Fhy2-r` |
| **Your Public Key Fingerprint** | `SHA256:uA0OB9GOj8YYlEbqLC2KXLpDQn1XZ6NCe9XHlfk39LE0` |
| **Expected Server Fingerprint** | `SHA256:5Ij30L5ol/uHzx7D7a6zdTQNGKIl6WSlRgHHAMRI2tY` |
| **Remote Home Directory** | `/storage/tracka/users/learner04` (`~`) |
| **Starter Project Directory** | `/storage/tracka/users/learner04/project` (`~/project`) |
| **Capstone Git Repo Path** | `/storage/tracka/users/learner04/project/iitkgp-capstone` |
| **Input Notebooks Folder** | `~/project/iitkgp-capstone/notebooks` |
| **Output Notebooks Folder** | `~/project/iitkgp-capstone/notebooks_output` |
| **GitHub Repository URL** | `https://github.com/soumen-chatterjee/iitkgp-capstone.git` |
| **Storage Quota** | `32 GiB` soft limit / `35 GiB` hard limit |
| **GPU Allowance** | `75 GPU-hours` total (no automatic reset; max 5 hours/job) |
| **Access Expiration** | `2 December 2026 at 17:27:52 IST` |

---

## 2. Step 1: Extract SSH Keys & Fix File Permissions

OpenSSH strictly rejects private keys that are readable by other users or system groups (causing `Load key ... Permission denied` or `Permission denied (publickey)`).

### On Windows (PowerShell)
1. Extract your assigned ZIP file (if not already extracted):
   ```powershell
   Expand-Archive `
     -Path "$env:USERPROFILE\Downloads\TrackA_VM03_learner04.zip" `
     -DestinationPath "$env:USERPROFILE\Downloads\TrackA_VM03_Group04"
   ```
2. Lock down permissions on `id_ed25519` so only your Windows account has read access:
   ```powershell
   $key = "C:\Users\Soumen\Downloads\TrackA_VM03_Group04\id_ed25519"
   icacls $key /reset
   icacls $key /inheritance:r
   icacls $key /grant:r "${env:USERNAME}:(R)"
   ```
   *(If `icacls` returns `Access is denied`, open PowerShell **as Administrator**, run `takeown /f $key`, and re-run the three `icacls` lines above.)*
3. **Verify:** Run `icacls $key`. Only your username with `(R)` should appear.

### On macOS / Linux (Terminal)
```bash
unzip "$HOME/Downloads/TrackA_VM03_learner04.zip" -d "$HOME/Downloads/TrackA_VM03_Group04"
chmod 600 "$HOME/Downloads/TrackA_VM03_Group04/id_ed25519"
```

---

## 3. Step 2: Configure SSH Alias & Verify Connection

1. Open (or create) your local SSH config file:
   * **Windows:** `C:\Users\Soumen\.ssh\config`
   * **macOS / Linux:** `~/.ssh/config`
2. Add the following host block (do **not** point `IdentityFile` to `.pub`, and do **not** use PowerShell variables like `$env:USERPROFILE` inside this file):
   ```text
   Host upgrad-l40s-vm03
       HostName 103.42.50.41
       Port 1026
       User learner04
       IdentityFile "C:\Users\Soumen\Downloads\TrackA_VM03_Group04\id_ed25519"
       IdentitiesOnly yes
   ```
3. Test the connection from PowerShell / Terminal:
   ```powershell
   ssh upgrad-l40s-vm03
   ```
4. **First-time verification:** Confirm the server's Ed25519 fingerprint matches `SHA256:5Ij30L5ol/uHzx7D7a6zdTQNGKIl6WSlRgHHAMRI2tY`, type `yes`, and enter your passphrase. Your prompt should change to `learner04@upgrad-l40s-vm03:~$`.

---

## 4. Step 3: Set Up VS Code with SSH FS & Fix the Integrated Terminal

First, install the extension:
1. Open **Microsoft VS Code** and press `Ctrl + Shift + X` (**Extensions**).
2. Search for **SSH FS** (published by **Kelvin Schoofs**) and click **Install**.

Now configure **SSH FS** using **Option A (Fast `settings.json` Copy-Paste)** or **Option B (UI Form)**.

### Option A: Fast Setup via `settings.json` (Recommended)
1. Press `Ctrl + Shift + P` in VS Code, type **Preferences: Open User Settings (JSON)**, and press `Enter`.
2. Add the `"sshfs.configs"` and `"terminal.integrated.cwd"` entries inside the top-level `{ ... }` JSON object (ensure there is a comma after the previous setting):
   ```json
   "sshfs.configs": [
     {
       "name": "upgrad-l40s-vm03",
       "label": "upgrad-l40s-vm03 (Track A)",
       "host": "103.42.50.41",
       "port": 1026,
       "username": "learner04",
       "root": "/storage/tracka/users/learner04/project",
       "privateKeyPath": "C:\\Users\\Soumen\\Downloads\\TrackA_VM03_Group04\\id_ed25519",
       "passphrase": true
     }
   ],
   "terminal.integrated.cwd": "C:\\Users\\Soumen"
   ```
   > **JSON Tips:**
   > * Windows paths inside JSON **must** use double backslashes (`\\`).
   > * `"passphrase": true` prompts you securely in the VS Code top bar whenever you connect (avoid storing plaintext passphrases inside `settings.json`).
3. Save `settings.json` (`Ctrl + S`).

### Option B: Setup via the SSH FS UI Form
1. Click the **SSH FS** icon in the left Activity Bar.
2. Next to **Configurations**, click **+** (*Create a SSH FS configuration*), type `upgrad-l40s-vm03`, press `Enter`, and click **Configure**.
3. Fill in these exact fields and click **Save**:
   * **Root:** `/storage/tracka/users/learner04/project`
   * **Host:** `103.42.50.41`
   * **Port:** `1026`
   * **Username:** `learner04`
   * **Private Key Path:** `C:\Users\Soumen\Downloads\TrackA_VM03_Group04\id_ed25519`
   * **Passphrase:** Select **Prompt**

### Mount Your Remote Folder & Open Terminals
1. Click the **SSH FS** icon in the Activity Bar, hover over `upgrad-l40s-vm03`, and click **Add as Workspace folder** (folder with `+`).
2. Enter your key passphrase in the top bar when prompted, then press `Ctrl + Shift + E` (**Explorer**) to verify your remote files appear.
3. **Opening Terminals Cleanly:**
   * **Direct Remote VM Terminal (Fastest):** Hover over `upgrad-l40s-vm03` in the **SSH FS** sidebar and click the **Open terminal** icon (`>_`).
   * **Local PowerShell Terminal (`Ctrl + \``):** With `"terminal.integrated.cwd"` set above, pressing `` Ctrl + ` `` opens local PowerShell cleanly without a missing Linux directory error; run `ssh upgrad-l40s-vm03` from there anytime.

---

## 5. Step 4: Configure Git & Connect to GitHub on the VM

Open a remote SSH terminal on `upgrad-l40s-vm03` and run the steps below.

### A. Set Global Git Identity (Preventing `GH007` Email Privacy Errors)
GitHub blocks pushes if your commit email is private (`GH007: Your push would publish a private email address`). Always use your GitHub `noreply` address found at `https://github.com/settings/emails` under **Keep my email addresses private**:

```bash
git config --global user.name "Soumen Chatterjee"
git config --global user.email "<your-id>+soumen-chatterjee@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global credential.helper store
```
> **Authentication Note:** GitHub requires a **Personal Access Token (PAT)** instead of your account password when pushing over HTTPS. Generate a fine-grained PAT with **Contents: Read and write** permission for `iitkgp-capstone` and paste it when prompted for a password on your first push. `credential.helper store` saves it in `~/.git-credentials` on the VM.

### B. Initialize the Repository, Standard Folders & `.gitignore`
Navigate to your project directory and create the standard `notebooks/`, `notebooks_output/`, and `logs/` folders:

```bash
mkdir -p ~/project/iitkgp-capstone/{notebooks,notebooks_output,logs}
cd ~/project/iitkgp-capstone
git init
git remote add origin https://github.com/soumen-chatterjee/iitkgp-capstone.git
```

Create a strict `.gitignore` so large model weights, virtual environments, Slurm logs, and credentials are never pushed to GitHub:

```bash
cat << 'EOF' > .gitignore
# Python & Virtual Environments
__pycache__/
*.py[cod]
.venv/
venv/
.ipynb_checkpoints/

# Slurm Logs & Model Checkpoints
logs/
*.out
*.err
checkpoints/
*.safetensors
*.bin
*.pt
*.pth
*.ckpt

# Secrets, Keys & Local Reference Docs
id_ed25519
*.pem
.git-credentials
.env
01_primary_user_initial_setup.md
vscode_vm_git_guide.md
.vscode/
EOF
```

### C. Commit & Push the Initial Branch
Check if GitHub already has a branch (`git ls-remote --heads origin`). For a fresh repository:

```bash
git branch -M main
git add .
git commit -m "Initial commit: project structure and .gitignore"
git push -u origin main
```
*(If you ever accidentally commit with a private email and hit `GH007`, update `git config --global user.email` to your `noreply` address, run `git commit --amend --reset-author --no-edit`, and re-run `git push -u origin main`.)*

---

## 6. Step 5: Install `uv` and Python 3.12.14 on the VM

We use **`uv`** (Astral's fast Python package and version manager) with **Python 3.12.14** because bleeding-edge releases (such as Python 3.15) lack pre-built binary wheels for CUDA `torch` and `bitsandbytes`.

1. **Install `uv` into `$HOME/.local/bin` (no `sudo` needed):**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   source "$HOME/.local/bin/env"
   uv --version
   ```
   *(Verify that `source "$HOME/.local/bin/env"` or `$HOME/.local/bin` is added to `~/.bashrc` so future SSH sessions recognize `uv` automatically.)*

2. **Install Python 3.12.14:**
   ```bash
   uv python install 3.12.14
   uv python list --only-installed
   ```
   *(If you previously installed Python 3.15 and want to reclaim disk space, remove it with `uv python uninstall 3.15`.)*

3. **Create the project virtual environment (`.venv`) inside `~/project/iitkgp-capstone`:**
   ```bash
   cd ~/project/iitkgp-capstone
   uv venv .venv --python 3.12.14 --clear
   source .venv/bin/activate
   python --version
   ```
   **Verification:** Your prompt displays `(.venv)` and `python --version` prints `Python 3.12.14`.

---

## 7. Step 6: Install All 19 Pinned Packages + `jupyter` & `nbconvert`

Across all four capstone notebooks, there are **19 unique packages**, plus `jupyter`, `nbconvert`, and `ipykernel` so notebooks can be executed headlessly via Slurm (`sbatch`). Because `torch==2.9.1+cu126` is a CUDA 12.6 wheel hosted on PyTorch's dedicated index, install it first, then install the remaining packages.

### A. Install PyTorch 2.9.1 (CUDA 12.6)
```bash
cd ~/project/iitkgp-capstone
uv pip install --python .venv/bin/python \
  --index-url https://download.pytorch.org/whl/cu126 \
  torch==2.9.1+cu126
```

### B. Install the Remaining 18 Pinned Packages + Jupyter Tooling
```bash
uv pip install --python .venv/bin/python \
  transformers==5.23.0 \
  peft==0.21.3 \
  accelerate==1.16.0 \
  bitsandbytes==0.50.2 \
  datasets==5.2.0 \
  trl==1.18.1 \
  scikit-learn==1.9.1 \
  scipy==1.18.1 \
  rouge-score==0.1.2 \
  pandas==3.1.1 \
  numpy==2.5.5 \
  matplotlib==3.11.1 \
  jinja2==3.1.6 \
  requests==2.34.2 \
  fastapi==0.165.0 \
  httpx==0.28.1 \
  pytest==9.2.0 \
  pyyaml==6.0.3 \
  jupyter \
  nbconvert \
  ipykernel
```

### C. Save a `requirements-lock.txt` Snapshot for Version Control (Recommended)
```bash
uv pip freeze --python .venv/bin/python > requirements-lock.txt
```

---

## 8. Step 7: Final Verification & GPU Health Check

### A. Verify Packages, Jupyter, Git & Quota (Login Shell)
Run this block on the VM to confirm Python, Jupyter, Git, and disk space are healthy:

```bash
cd ~/project/iitkgp-capstone

# 1. Verify Python, core ML imports & Jupyter nbconvert
.venv/bin/python -c "import torch, transformers, peft, bitsandbytes, trl; print('Python OK | Torch:', torch.__version__, '| Transformers:', transformers.__version__)"
.venv/bin/jupyter nbconvert --version

# 2. Verify all 19 pinned packages + jupyter
uv pip list --python .venv/bin/python | grep -E "torch|transformers|peft|accelerate|bitsandbytes|datasets|trl|scikit-learn|scipy|rouge-score|pandas|numpy|matplotlib|jinja2|requests|fastapi|httpx|pytest|PyYAML|jupyter|nbconvert|ipykernel"

# 3. Verify Git remote & status
git remote -v
git status

# 4. Check disk usage against the 32 GiB soft / 35 GiB hard limit
quota -s
```

### B. Test the GPU via Slurm (`sbatch`)
Because direct GPU access is blocked in the SSH login shell, verify CUDA and PyTorch GPU visibility by submitting a lightweight, 5-second Slurm job (`test_gpu.sbatch`):

1. **Create `test_gpu.sbatch`:**
   ```bash
   cd ~/project/iitkgp-capstone
   mkdir -p logs

   cat << 'EOF' > test_gpu.sbatch
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
   EOF
   ```
2. **Submit and check the output:**
   ```bash
   sbatch test_gpu.sbatch
   squeue --me
   ```
3. **Read the log once it finishes** (replace `<JOB_ID>` with the number returned by `sbatch`):
   ```bash
   cat logs/test_gpu-<JOB_ID>.out
   cat logs/test_gpu-<JOB_ID>.err
   ```
   **Verification:** The `.out` log prints `CUDA available: True`, the NVIDIA L40S GPU name and VRAM, and `Matrix multiply test OK`, while `.err` is empty.

---

## 9. SSH FS Quick Troubleshooting

| SSH FS Symptom / Error | Cause & Fix |
| :--- | :--- |
| **`All configured authentication methods failed`** | Usually caused by: (1) pointing `privateKeyPath` to `id_ed25519.pub` instead of `id_ed25519`, (2) missing the passphrase prompt at the top of the VS Code window, or (3) single backslashes (`\`) instead of double backslashes (`\\`) in `settings.json`. |
| **`Error: ENOENT` or `Cannot read privateKeyPath`** | The path in `privateKeyPath` does not exist or Windows permissions block reading it. Verify the exact path and re-run the `icacls` commands in **Step 1**. |
| **Folder won't expand or files fail to save after sleep/Wi-Fi switch** | The SFTP session timed out. In the **SSH FS** sidebar, click the **Disconnect** icon next to `upgrad-l40s-vm03` (or press `Ctrl + Shift + P` → **Developer: Reload Window**) and reconnect. |
| **Terminal fails: `Starting directory (cwd) "\storage\..." does not exist`** | VS Code tried to open local PowerShell in the mounted Linux path. Set `"terminal.integrated.cwd": "C:\\Users\\Soumen"` in `settings.json`, or use the **SSH FS** `>_` (**Open terminal**) button. |
| **Detailed error logs needed** | Open the **Output** panel (`Ctrl + Shift + U`) and select **SSH FS** from the top-right dropdown to see exact SFTP/SSH connection logs. |

Once all checks pass, hand **`02_team_user_daily_workflow.md`** to your team members so they can connect and start coding immediately.