import os
import shutil
import numpy as np
from pathlib import Path

source_dir = '/Users/chrisfairless/Projects/UNU/idmc/forecast/displacement_forecast/output/'
target_dir = '/Users/chrisfairless/Projects/UNU/idmc/forecast/displacement_forecast_page/data/'

for d in os.listdir(source_dir):
    dir = Path(source_dir, d)
    if not os.path.isdir(dir):
        continue

    print(f'Working on directory {d}:')
    if not np.all([s.isdigit() for s in d]):
        print("This folder doesn't look like a forecast output dir. Skipping.")
        continue

    report_dir = Path(dir, 'report')
    if not os.path.exists(report_dir):
        print('No report folder. Skipping.')
        continue

    if not os.path.exists(Path(report_dir, 'report.md')):
        print('No report file. Skipping.')
        continue

    write_dir = Path(target_dir, d)
    write_report_dir = Path(target_dir, d, 'report')
    write_report_path = Path(target_dir, d, 'report', 'report.md')

    os.makedirs(write_dir, exist_ok=True)
    os.makedirs(write_report_dir, exist_ok=True)

    if os.path.exists(write_report_path):
        print('Report already at the write location. Skipping.')
        continue

    for f in os.listdir(report_dir):
        src_file = Path(report_dir, f)
        dst_file = Path(write_report_dir, f)
        shutil.copy(src_file, dst_file)
    print(f'Copied files from {report_dir} to {write_report_dir}.')

print('Copying home page')
shutil.copy(Path(source_dir, 'index.html'), Path(target_dir, 'index.html'))
shutil.copy(Path(source_dir, 'index.md'), Path(target_dir, 'index.md'))