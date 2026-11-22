# Track A Remote VM: VS Code, SSH & Git Setup Guide

This guide provides the **most reliable workflow** for developing on the IIT KGP Capstone GPU VM (`upgrad-l40s-vm03`) from **Windows** using **Visual Studio Code**, **OpenSSH**, and **Git/GitHub**.

> **Important Note on VS Code Remote-SSH:**
> `upgrad-l40s-vm03` explicitly disables learner SSH port forwarding (`AllowTcpForwarding no`). Because Microsoft's **Remote - SSH** extension requires SSH port forwarding, it will hang indefinitely on *"Waiting for port forwarding to be ready"*. Use the **Local VS Code + Integrated SSH Terminal + Git Sync** workflow below instead—it is fast, reliable, and works within all VM policies.

> **Security Warning:** This personal reference file contains your SSH key passphrase. **Keep this file strictly on your local computer** and **never commit or push it to GitHub** (it is included in the `.gitignore` template below for safety).

---

## Quick Reference Details

| Setting | Value |
| :--- | :--- |
| **Server IP** | `103.42.50.41` |
| **SSH Port** | `1026` |
| **Username** | `Group04` |
| **Private Key File** | `id_ed25519` (from `TrackA_VM03_Group04.zip`) |
| **Key Passphrase** | `2RBENPka3HLZqbJiXwU9-qC1I7Fhy2-r` |
| **Your Public Key Fingerprint** | `SHA256:uA0OB9GOj8YYlEbqLC2KXLpDQn1XZ6NCe9XHlfk39LE0` |
| **Expected Server Fingerprint (Ed25519)** | `SHA256:5Ij30L5ol/uHzx7D7a6zdTQNGKIl6WSlRgHHAMRI2tY` |
| **Remote Home Directory** | `/storage/tracka/users/Group04` |
| **Starter Project Directory** | `~/project` |
| **Python Environment** | `~/venv` |
| **GitHub Repository** | `https://github.com/soumen-chatterjee/iitkgp-capstone.git` |
| **Access Expires** | `2 December 2026 at 17:27:52 IST` |

---

## Step 1: Extract, Secure & Configure SSH (One-Time Setup)

Save `TrackA_VM03_Group04.zip` in your `Downloads` folder, then open **Windows PowerShell** and run these commands once.

### 1. Extract the ZIP
```powershell
Expand-Archive `
  -Path "$env:USERPROFILE\Downloads\TrackA_VM03_Group04.zip" `
  -DestinationPath "$env:USERPROFILE\Downloads\TrackA_VM03_Group04"
```

### 2. Lock Down Key Permissions (Prevents `Permission denied (publickey)`)
Windows OpenSSH rejects private keys that other users or system groups can read:
```powershell
$key = "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519"
icacls $key /inheritance:r
icacls $key /grant:r "$($env:USERNAME):(R)"
```

### 3. Verify Your Key Fingerprint
```powershell
ssh-keygen -lf "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519.pub"
```
Confirm the output matches: `SHA256:uA0OB9GOj8YYlEbqLC2KXLpDQn1XZ6NCe9XHlfk39LE0`

### 4. Create an SSH Alias (`~/.ssh/config`)
So you can connect with a short `ssh upgrad-l40s-vm03` command, open `C:\Users\<YourWindowsUsername>\.ssh\config` in VS Code (or Notepad) and add:
```text
Host upgrad-l40s-vm03
    HostName 103.42.50.41
    Port 1026
    User Group04
    IdentityFile "C:\Users\<YourWindowsUsername>\Downloads\TrackA_VM03_Group04\id_ed25519"
    IdentitiesOnly yes
```
*(Replace `<YourWindowsUsername>` with your actual Windows username. Do not use `$env:USERPROFILE` or `.pub` here.)*

### 5. Test the SSH Connection
```powershell
ssh upgrad-l40s-vm03
```
* On first connection, verify the server fingerprint matches:
  `SHA256:5Ij30L5ol/uHzx7D7a6zdTQNGKIl6WSlRgHHAMRI2tY`
  Type `yes` and press `Enter`.
* Enter your passphrase when prompted: `2RBENPka3HLZqbJiXwU9-qC1I7Fhy2-r` (characters will not appear as you type).

> **macOS / Linux Equivalent:**
> ```bash
> unzip "$HOME/Downloads/TrackA_VM03_Group04.zip" -d "$HOME/Downloads/TrackA_VM03_Group04"
> chmod 600 "$HOME/Downloads/TrackA_VM03_Group04/id_ed25519"
> ```

---

## Step 2: Configure Git & GitHub on the Remote VM

While logged into the VM via `ssh upgrad-l40s-vm03`, configure Git and connect `~/project` to your GitHub repository.

### 1. Set Your Git Identity
```bash
git config --global user.name "Soumen Chatterjee"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
```

### 2. Set Up GitHub Authentication (Personal Access Token)
GitHub requires a **Personal Access Token (PAT)** instead of your account password for HTTPS:
1. On GitHub in your browser, go to **Settings → Developer settings → Personal access tokens → Fine-grained tokens** (or **Tokens (classic)**).
2. Create a token with **Repository permissions → Contents: Read and write** (Fine-grained) or the **`repo`** scope (Classic), and copy it.
3. On the VM, enable Git's credential helper so you only enter the token once:
   ```bash
   git config --global credential.helper store
   ```
   *(On your first `git push` or `git pull`, enter your GitHub username and paste the PAT as the password.)*

> **Cleanup Reminder:** Before access expires, remove saved credentials on the VM with `rm -f ~/.git-credentials` and revoke the token on GitHub.

### 3. Add a `.gitignore` File (Mandatory Before First Commit)
Keep large model weights, checkpoints, logs, and credentials out of GitHub:
```bash
cd ~/project
cat << 'EOF' > .gitignore
# Python & Virtual Environments
__pycache__/
*.py[cod]
venv/
.venv/
.ipynb_checkpoints/

# Training Logs & Outputs
logs/
*.out
*.err

# Model Weights & Checkpoints (too large for GitHub)
checkpoints/
*.safetensors
*.bin
*.pt
*.pth
*.ckpt
*.gguf

# Sensitive / Local Reference Files
id_ed25519
*.pem
.git-credentials
vscode_vm_git_guide.md

# OS / Editor files
.DS_Store
.vscode/
EOF
```

### 4. Link `~/project` and Push Starter Files to GitHub
```bash
cd ~/project
git init
git remote add origin https://github.com/soumen-chatterjee/iitkgp-capstone.git

# If your GitHub repo already has files (e.g., README.md), pull them first:
git pull origin main --allow-unrelated-histories

git add .
git commit -m "Initial commit with Track A starter files"
git push -u origin main
```

---

## Step 3: Most Reliable Daily Workflow (Recommended)

### Option 1: Local VS Code + Integrated SSH Terminal + Git Sync (Most Reliable)
This gives you full VS Code editing, linting, and Copilot/extensions locally with zero connection drops, while running all Slurm training jobs on the VM.

1. **Clone the repository locally on Windows:**
   In PowerShell (in your preferred local projects folder):
   ```powershell
   git clone https://github.com/soumen-chatterjee/iitkgp-capstone.git
   code iitkgp-capstone
   ```
2. **Open two terminal tabs inside VS Code** (press `` Ctrl + ` ``, then click `+` to add a second terminal):
   * **Terminal 1 (Local PowerShell):** Used for `git add`, `git commit`, and `git push`.
   * **Terminal 2 (Remote VM SSH):** Run `ssh upgrad-l40s-vm03` and `cd ~/project`. Used for `git pull` and Slurm commands (`sbatch`, `squeue`, `tail`).
3. **Your smooth edit-and-train loop:**
   * Edit `train.py`, `train.sbatch`, or `infer.py` in local VS Code.
   * **Local terminal:**
     ```powershell
     git add .
     git commit -m "Update hyperparameters"
     git push
     ```
   * **VM SSH terminal:**
     ```bash
     git pull
     sbatch train.sbatch
     squeue --me
     ```

---

### Option 2: Direct Quick File Upload with `scp` (No Git Commit Needed)
If you want to test a quick edit to a single file (like `train.sbatch` or a dataset file) without making a Git commit, run `scp` from a **local Windows PowerShell** terminal:

```powershell
# Upload a single file from Windows to the VM
scp -i "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519" `
  -P 1026 .\train.sbatch Group04@103.42.50.41:~/project/

# Upload a dataset file to the VM
scp -i "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519" `
  -P 1026 .\my_dataset.jsonl Group04@103.42.50.41:~/project/
```
*(Note: `scp` uses uppercase `-P` for the port number.)*

---

### Option 3: VS Code Remote - Tunnels (If You Want Direct Remote Editing)
Unlike Remote-SSH, **Remote - Tunnels** connects over outbound HTTPS rather than SSH port forwarding. *(This works only if the VM allows outbound HTTPS to GitHub/Microsoft.)*

1. **On the VM (via SSH):**
   ```bash
   curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-linux-x64' --output vscode_cli.tar.gz
   tar -xf vscode_cli.tar.gz
   ./code tunnel
   ```
   Follow the prompt to authenticate with your GitHub account.
2. **In local VS Code:**
   * Install the **Remote - Tunnels** extension (`ms-vscode.remote-server`).
   * Press `Ctrl + Shift + P` → **`Remote Tunnels: Connect to Tunnel...`** → select your VM.
   * Open `/storage/tracka/users/Group04/project`.

*(Tip: Keep an eye on `quota -s` if using Remote - Tunnels, as VS Code's server files take ~200–400 MB of your storage quota.)*

---

## Quick Reference: Slurm Jobs, Limits & Backups

### Running & Monitoring Jobs (On the VM)
Direct GPU use from the SSH login shell is blocked. Always run training and GPU inference through **Slurm**:
```bash
cd ~/project
mkdir -p logs
sbatch train.sbatch               # Submit job (note the returned JOB_ID)
squeue --me                       # Check status (PD = Pending, R = Running)
sacct -X --starttime today --format=JobID,JobName,State,Elapsed,AllocTRES

# Inspect logs & training summary (replace 123 with your JOB_ID)
JOB_ID=123
tail -n 40 "$HOME/project/logs/qlora-$JOB_ID.out"
tail -n 40 "$HOME/project/logs/qlora-$JOB_ID.err"
cat "$HOME/checkpoints/job-$JOB_ID/training_summary.json"

scancel "$JOB_ID"                 # Cancel your own job
quota -s                          # Check storage quota (32 GiB soft / 35 GiB hard)
source ~/venv/bin/activate        # Activate Python env when inspecting scripts
```

### Cohort Limits
* **GPU Allowance:** 75 GPU-hours per learner (no automatic reset; waiting in queue does not consume GPU time).
* **Concurrency:** 1 running GPU job across the entire VM at a time; max 1 running + 1 pending job per learner.
* **Max Job Duration:** 5 hours with `--gres=gpu:1`.
* **Storage:** 32 GiB soft / 35 GiB hard limit (shared base model weights do not count against your quota).

### Backing Up Work to Windows (Before `2 December 2026 at 17:27:52 IST`)
Run in a **local Windows PowerShell** window (not inside the VM):
```powershell
# Backup project code
scp -i "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519" `
  -P 1026 -r Group04@103.42.50.41:project `
  "$env:USERPROFILE\Downloads\TrackA_project_backup"

# Backup saved LoRA adapters/checkpoints
scp -i "$env:USERPROFILE\Downloads\TrackA_VM03_Group04\id_ed25519" `
  -P 1026 -r Group04@103.42.50.41:checkpoints `
  "$env:USERPROFILE\Downloads\TrackA_checkpoints_backup"
```

---

## Troubleshooting

1. **VS Code Remote-SSH hangs on *"Waiting for port forwarding to be ready"*:**
   * Expected behavior on VM03 due to disabled SSH port forwarding. Close the Remote-SSH window and use **Option 1 (Local VS Code + Integrated SSH Terminal + Git Sync)**.
2. **`Permission denied (publickey)` in PowerShell:**
   * Re-run the `icacls` permission commands in **Step 1**.
   * Verify you are pointing to `id_ed25519` (not `id_ed25519.pub`) and using `User Group04`.
   * Run `ssh -v upgrad-l40s-vm03` to inspect detailed debug output.
3. **Storage Quota Exceeded:**
   * Run `quota -s` and delete obsolete run folders inside `~/checkpoints/`.
4. **Connection Timeout:**
   * Verify your internet connection and contact your coordinator with the timestamp and SSH port `1026`. Never share your private key or passphrase.