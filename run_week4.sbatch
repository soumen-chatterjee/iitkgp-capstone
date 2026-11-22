#!/bin/bash
#SBATCH --job-name=week4_serving
#SBATCH --gres=gpu:1
#SBATCH --time=02:00:00
#SBATCH --output=logs/week4-%j.out
#SBATCH --error=logs/week4-%j.err

mkdir -p logs notebooks_output
source /storage/tracka/users/learner04/project/iitkgp-capstone/.venv/bin/activate

jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=-1 \
  notebooks/it_helpdesk_week4_serving.ipynb \
  --output-dir notebooks_output \
  --output it_helpdesk_week4_serving.ipynb
