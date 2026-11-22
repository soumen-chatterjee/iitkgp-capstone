#!/bin/bash
#SBATCH --job-name=week3_rag
#SBATCH --gres=gpu:1
#SBATCH --time=02:00:00
#SBATCH --output=logs/week3-%j.out
#SBATCH --error=logs/week3-%j.err

mkdir -p logs notebooks_output
source /storage/tracka/users/learner04/project/iitkgp-capstone/.venv/bin/activate

jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=-1 \
  notebooks/it_helpdesk_week3_rag.ipynb \
  --output-dir notebooks_output \
  --output it_helpdesk_week3_rag.ipynb
