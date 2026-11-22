# Track A Remote VM: Team Member Daily Workflow Guide

Welcome to the IIT KGP Capstone environment on `upgrad-l40s-vm03`. The primary user has already provisioned the Git repository, `uv`, Python **3.12.14**, and the `.venv` virtual environment containing all **19 pinned ML/Python packages**.

This guide explains how **subsequent users / team members** connect to the VM via VS Code, edit `.ipynb` and `.py` files, run GPU training and inference jobs through **Slurm**, and collaborate cleanly using **Git & GitHub**.

---

## 1. Shared Account Ground Rules & Limits

All team members share the `learner04` account on `upgrad-l40s-vm03`. Coordinate before running heavy jobs or changing shared files:

| Resource / Policy | Limit / Rule |
| :--- | :--- |
| **GPU Allowance** | **75 GPU-hours total** for the account (no automatic reset). Idle allocated GPU time is billed; queue wait time is not. |
| **Job Concurrency** | Only **1 GPU job runs across the entire VM** at a time. Max **1 running + 1 pending** job for `learner04`. |
| **Max Job Duration** | **5 hours** maximum per job, always requesting `--gres=gpu:1`. |
| **Direct GPU Access** | **Blocked** in the SSH login shell. All model training, fine-tuning, and GPU inference **must** run via Slurm (`sbatch` or `srun`). |
| **Private Storage Quota** | **32 GiB soft / 35 GiB hard** limit. Check frequently with `quota -s`. |
| **Access Expiration** | **`2 December 2026 at 17:27:52 IST`** — all jobs cancel and SSH expires at this time. Back up work beforehand. |

> **Important:** Do **not** install Microsoft's **Remote - SSH** extension for this VM. SSH port forwarding is disabled on `upgrad-l40s-vm03`, so Remote-SSH will hang indefinitely. Always use **SSH FS** + **VS Code's Integrated Terminal**.

---

## 2. One-Time Local Workstation Setup

Get the `id_ed25519` private key file and passphrase from your primary user/coordinator and save the key locally (e.g., inside `Downloads\TrackA_VM03_Group04\`).

### Step 1: Protect the Private Key File
* **Windows (PowerShell):** Replace `<YourUsername>` and the path if you saved the key elsewhere:
  ```powershell
  $key = "C:\Users\<YourUsername>\Downloads\TrackA_VM03_Group04\id_ed25519"
  icacls $key /reset
  icacls $key /inheritance:r
  icacls $key /grant:r "${env:USERNAME}:(R)"
  ```
* **macOS / Linux (Terminal):**
  ```bash
  chmod 600 "$HOME/Downloads/TrackA_VM03_Group04/id_ed25519"
  ```

### Step 2: Add the SSH Alias (`~/.ssh/config`)
Open `C:\Users\<YourUsername>\.ssh\config` (Windows) or `~/.ssh/config` (macOS/Linux) and add:
```text
Host upgrad-l40s-vm03
    HostName 103.42.50.41
    Port 1026
    User learner04
    IdentityFile "C:\Users\<YourUsername>\Downloads\TrackA_VM03_Group04\id_ed25519"
    IdentitiesOnly yes
```
*(On macOS/Linux, use the Unix path such as `/Users/<YourUsername>/Downloads/TrackA_VM03_Group04/id_ed25519`.)*

Test in a terminal with `ssh upgrad-l40s-vm03`. On first connection, verify the server fingerprint matches:
`SHA256:5Ij30L5ol/uHzx7D7a6zdTQNGKIl6WSlRgHHAMRI2tY`
Type `yes` and enter the key passphrase.

### Step 3: Set Up VS Code with SSH FS (Copy-Paste `settings.json` or UI Form)
First, open **VS Code**, press `Ctrl + Shift + X`, search for **SSH FS** (by **Kelvin Schoofs**), and click **Install**.

#### Option A: Fast Copy-Paste into `settings.json` (Recommended)
1. Press `Ctrl + Shift + P` → type **Preferences: Open User Settings (JSON)** → press `Enter`.
2. Paste the block below inside the outer `{ ... }` JSON object, replacing `<YourUsername>` with your actual username:
   ```json
   "sshfs.configs": [
     {
       "name": "upgrad-l40s-vm03",
       "label": "upgrad-l40s-vm03 (Track A)",
       "host": "103.42.50.41",
       "port": 1026,
       "username": "learner04",
       "root": "/storage/tracka/users/learner04/project",
       "privateKeyPath": "C:\\Users\\<YourUsername>\\Downloads\\TrackA_VM03_Group04\\id_ed25519",
       "passphrase": true
     }
   ],
   "terminal.integrated.cwd": "C:\\Users\\<YourUsername>"
   ```
   *(On **macOS / Linux**, use forward slashes instead, e.g., `"/Users/<YourUsername>/Downloads/TrackA_VM03_Group04/id_ed25519"` and `"/Users/<YourUsername>"`.)*
3. Save `settings.json` (`Ctrl + S`).

#### Option B: Configure via the SSH FS UI Form
1. Click the **SSH FS** icon in the left Activity Bar → click **+** next to **Configurations** → name it `upgrad-l40s-vm03` → click **Configure**.
2. Enter:
   * **Root:** `/storage/tracka/users/learner04/project`
   * **Host:** `103.42.50.41`
   * **Port:** `1026`
   * **Username:** `learner04`
   * **Private Key Path:** Your local path to `id_ed25519`
   * **Passphrase:** Select **Prompt**
3. Click **Save**, and set `terminal.integrated.cwd` in VS Code Settings (`Ctrl + ,`) to your local home directory to prevent local terminal launch errors.

#### Mount the Remote Folder
Hover over `upgrad-l40s-vm03` in the **SSH FS** sidebar and click **Add as Workspace folder** (folder with `+`). Enter your passphrase in the top bar when prompted. Press `Ctrl + Shift + E` (**Explorer**) to see and edit all VM files directly.

---

## 3. Opening a Remote Terminal & Activating the Environment

You have two ways to open a terminal on the VM inside VS Code:
* **Method A (Fastest):** Click the **SSH FS** icon → hover over `upgrad-l40s-vm03` → click the **Open terminal** (`>_`) icon.
* **Method B (Standard Terminal):** Press `` Ctrl + ` `` to open a local terminal and run `ssh upgrad-l40s-vm03`.

Once logged into the VM, navigate to the repo and activate the shared **`uv`** virtual environment:

```bash
cd ~/project/iitkgp-capstone
source .venv/bin/activate
```

**Verify the environment is active:**
```bash
which python          # Should point to .../iitkgp-capstone/.venv/bin/python
python --version      # Should print Python 3.12.14
```

> **Note on Installing New Packages:** Do **not** blindly upgrade `torch`, `transformers`, `peft`, or `bitsandbytes` (they are pinned to match the 4 capstone notebooks). If you must add a lightweight utility package, coordinate with the team and install it with `uv`:
> ```bash
> source "$HOME/.local/bin/env"
> uv pip install --python .venv/bin/python <package-name>
> ```

---

## 4. Coding in `.py` and `.ipynb` Files

### Editing Files Directly on the VM
* Open any `.py`, `.sbatch`, `.jsonl`, or `.ipynb` file from the **Explorer** sidebar (`upgrad-l40s-vm03`).
* When you press `Ctrl + S`, **SSH FS** saves your changes immediately to `/storage/tracka/users/learner04/project/...` on the VM.

### Important: Running `.ipynb` Notebooks on This VM
Because `upgrad-l40s-vm03` has **no hosted Jupyter server**, **no SSH port forwarding**, and **blocks direct GPU usage in the login shell**, clicking the "Run Cell" button inside VS Code on an SSH FS-mounted notebook will **not** execute on the VM's GPU.

Use one of these two workflows for notebooks:
1. **Workflow A — Convert/Run Notebooks via Slurm (For GPU Execution):**
   * Edit the `.ipynb` file (or extract your training/evaluation logic into a `.py` script like `train.py` or `infer.py`) using VS Code.
   * Run the script inside a Slurm job using the `.venv` interpreter:
     ```bash
     # Inside your .sbatch script:
     ~/project/iitkgp-capstone/.venv/bin/python train.py
     ```
   * If you want Slurm to execute an `.ipynb` file end-to-end (provided `nbconvert` or `papermill` is installed in `.venv`), you can run it inside an `.sbatch` script:
     ```bash
     ~/project/iitkgp-capstone/.venv/bin/jupyter nbconvert --to notebook --execute my_notebook.ipynb --output my_notebook_out.ipynb
     ```
2. **Workflow B — Lightweight CPU Inspection in the VM Terminal:**
   * For quick syntax checks, dataset inspection, or `pytest` unit tests that do **not** touch the GPU:
     ```bash
     cd ~/project/iitkgp-capstone
     source .venv/bin/activate
     pytest
     python train.py --help
     ```

---

## 5. Running & Monitoring GPU Jobs with Slurm

All GPU training and inference must go through Slurm.

### 1. Ensure Your `.sbatch` Script Uses the `uv` `.venv`
Before submitting, check your `train.sbatch` file in VS Code. Make sure it:
* Keeps `#SBATCH --gres=gpu:1`
* Requests a realistic time limit (starter is 2 hours; hard maximum is 5 hours: `#SBATCH --time=02:00:00`)
* Writes to a **new, job-specific output directory** so you don't overwrite a teammate's adapter
* Activates your `uv` environment (`source ~/project/iitkgp-capstone/.venv/bin/activate`) instead of the default `~/venv` if your code relies on the 19 pinned packages.

### 2. Submit & Monitor a Job
```bash
cd ~/project/iitkgp-capstone   # (or ~/project for starter scripts)
mkdir -p logs
sbatch train.sbatch            # Returns: Submitted batch job <JOB_ID>
squeue --me                    # PD = Pending (waiting for GPU), R = Running
```
* Do **not** resubmit a job just because its state is `PD` (only 1 GPU job runs at a time across all 5 learners).
* Submitted jobs continue running safely even after you close VS Code or disconnect SSH.

### 3. Check Completed Jobs & Inspect Logs
```bash
# View final status & elapsed time for today's jobs (replace 'today' with YYYY-MM-DD if older)
sacct -X --starttime today --format=JobID,JobName,State,Elapsed,AllocTRES

# Inspect stdout, stderr, and training summary (replace 123 with your JOB_ID)
JOB_ID=123
tail -n 40 "$HOME/project/logs/qlora-$JOB_ID.out"
tail -n 40 "$HOME/project/logs/qlora-$JOB_ID.err"
cat "$HOME/checkpoints/job-$JOB_ID/training_summary.json"
```

### 4. Cancel a Job (Save GPU-Hours!)
If a job is stuck, misconfigured, or no longer needed, cancel it immediately so you don't burn the 75 GPU-hour allowance:
```bash
scancel "$JOB_ID"
```

---

## 6. Git & GitHub Collaboration Workflow

Because all team members share `~/project/iitkgp-capstone` on the VM, follow this disciplined workflow to avoid overwriting each other's work:

### Before Starting Work
```bash
cd ~/project/iitkgp-capstone
git status          # Check if a teammate left uncommitted edits
git pull            # Sync latest changes from GitHub
```

### After Editing Code or Notebooks
1. **Review what changed** (never commit large datasets, checkpoints, logs, or `.venv/`):
   ```bash
   git status
   git diff
   ```
2. **Stage, commit, and push:**
   ```bash
   git add <file1> <file2>
   git commit -m "Clear description of your change (e.g., Add LoRA rank 16 eval script)"
   git push
   ```
3. **Working on a Feature Branch (Recommended for Parallel Edits):**
   ```bash
   git checkout -b feature/<your-name>-<task>
   # ... edit, commit ...
   git push -u origin feature/<your-name>-<task>
   ```
   Then open a Pull Request on GitHub (`https://github.com/soumen-chatterjee/iitkgp-capstone`) to merge cleanly into `main`.

> **Tip:** If you commit from the shared VM, Git uses the global author configured on `learner04`. To attribute a specific commit to yourself without changing the global config, pass `--author`:
> ```bash
> git commit --author="Your Name <your-github-id+username@users.noreply.github.com>" -m "Your message"
> ```

---

## 7. Storage Cleanup & Backing Up Before Access Expires

### Check & Manage Disk Quota
```bash
quota -s
du -sh ~/project/* ~/checkpoints/* 2>/dev/null
```
Each training run keeps periodic checkpoints plus the final adapter under `~/checkpoints/job-<JOB_ID>`. Delete obsolete failed runs (`rm -rf ~/checkpoints/job-<OLD_ID>`) to stay comfortably below the **32 GiB soft limit**.

### Download Code & Trained Adapters to Your Local Computer
Run these commands in a **local terminal** (not inside the VM) regularly, and **definitely before `2 December 2026 at 17:27:52 IST`**:

* **Windows PowerShell:**
  ```powershell
  # Backup project code
  scp -i "C:\Users\<YourUsername>\Downloads\TrackA_VM03_Group04\id_ed25519" `
    -P 1026 -r learner04@103.42.50.41:project `
    "$env:USERPROFILE\Downloads\TrackA_project_backup"

  # Backup saved LoRA adapters/checkpoints
  scp -i "C:\Users\<YourUsername>\Downloads\TrackA_VM03_Group04\id_ed25519" `
    -P 1026 -r learner04@103.42.50.41:checkpoints `
    "$env:USERPROFILE\Downloads\TrackA_checkpoints_backup"
  ```
* **macOS / Linux:**
  ```bash
  scp -i "$HOME/Downloads/TrackA_VM03_Group04/id_ed25519" \
    -P 1026 -r learner04@103.42.50.41:project \
    "$HOME/Downloads/TrackA_project_backup"
  ```
*(Note: `scp` uses uppercase `-P 1026` for the port, whereas `ssh` uses lowercase `-p 1026`.)*

---

## 8. Quick Troubleshooting Cheat Sheet

### A. VS Code SSH FS Troubleshooting

| SSH FS Symptom / Error | Cause & Fix |
| :--- | :--- |
| **`All configured authentication methods failed`** | Check that `privateKeyPath` points to `id_ed25519` (not `.pub`), uses double backslashes (`\\`) on Windows inside `settings.json`, and that you entered the passphrase in the top VS Code bar before it timed out. |
| **Remote files stop loading or saving after sleep / network switch** | The SFTP connection dropped. Click **Disconnect** next to `upgrad-l40s-vm03` in the **SSH FS** sidebar (or run `Ctrl + Shift + P` → **Developer: Reload Window**) and mount again. |
| **VS Code terminal fails: `Starting directory (cwd) "\storage\..." does not exist`** | VS Code tried to open local PowerShell in a remote Linux path. Use the **SSH FS** `>_` terminal icon, or set `"terminal.integrated.cwd"` to your local home folder in `settings.json`. |
| **Need detailed SSH FS logs** | Press `Ctrl + Shift + U` (**Output** panel) and choose **SSH FS** from the dropdown menu on the right. |

### B. SSH, Python (`uv`), Slurm & Git Troubleshooting

| Symptom / Error | Cause & Fix |
| :--- | :--- |
| **`Load key ... Permission denied`** | Windows/macOS key permissions are too open. Re-run `icacls` (Windows) or `chmod 600` (macOS/Linux) from Section 2. |
| **`uv: command not found`** | Load `uv` into your shell PATH: `source "$HOME/.local/bin/env"`. |
| **`ModuleNotFoundError` when running Python** | You forgot to activate the `uv` environment. Run `source ~/project/iitkgp-capstone/.venv/bin/activate` (or call `.venv/bin/python` directly in `.sbatch`). |
| **`CUDA not available` or GPU blocked in terminal** | Direct GPU access is blocked on the login node. Submit your script via `sbatch` or `srun --gres=gpu:1`. |
| **`GH007: Your push would publish a private email`** | Ensure `git config --global user.email` is set to a `@users.noreply.github.com` address, then run `git commit --amend --reset-author --no-edit` and `git push`. |
| **`Disk quota exceeded`** | Run `quota -s` and delete old run folders inside `~/checkpoints/` or old logs inside `~/project/logs/`. |