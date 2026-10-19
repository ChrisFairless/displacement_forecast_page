import os
import shutil
import numpy as np
from pathlib import Path

index_dir = '/Users/chrisfairless/Data/UNU/idmc/displacement_forecast/output/'
source_dir = '/Users/chrisfairless/Data/UNU/idmc/displacement_forecast/output/forecasts/'
target_dir = '/Users/chrisfairless/OneDrive/Projects/UNU/idmc/forecast/displacement_forecast_page/docs/'

overwrite = True
skip_html = True
verbose = False

assert os.path.exists(source_dir)
assert os.path.exists(target_dir)

stats = {
    'Directories scanned': 0,
    'Report directories copied': 0,
    'Skipped non-forecast directories': 0,
    'Skipped missing report folders': 0,
    'Skipped missing report files': 0,
    'Skipped existing reports': 0,
    'Home page file copied': 0,
}

for d in os.listdir(source_dir):
    dir = Path(source_dir, d)
    if not os.path.isdir(dir):
        continue

    stats['Directories scanned'] += 1
    if verbose:
        print(f'Working on directory {d}:')
    if not np.all([s.isdigit() for s in d]):
        stats['Skipped non-forecast directories'] += 1
        if verbose:
            print("This folder doesn't look like a forecast output dir. Skipping.")
        continue

    report_dir = Path(dir, 'report')
    if not os.path.exists(report_dir):
        stats['Skipped missing report folders'] += 1
        if verbose:
            print('No report folder. Skipping.')
        continue

    if not os.path.exists(Path(report_dir, 'report.md')):
        stats['Skipped missing report files'] += 1
        if verbose:
            print('No report file. Skipping.')
        continue

    write_dir = Path(target_dir, d)
    write_report_dir = Path(target_dir, d, 'report')
    write_report_path = Path(target_dir, d, 'report', 'report.md')

    os.makedirs(write_dir, exist_ok=True)
    os.makedirs(write_report_dir, exist_ok=True)

    if os.path.exists(write_report_path) and not overwrite:
        stats['Skipped existing reports'] += 1
        if verbose:
            print('Report already at the write location. Skipping.')
        continue

    for f in os.listdir(report_dir):
        src_file = Path(report_dir, f)
        if skip_html and 'html' in str(src_file):
            continue
        dst_file = Path(write_report_dir, f)
        shutil.copy(src_file, dst_file)

    stats['Report directories copied'] += 1
    if verbose:
        print(f'Copied files from {report_dir} to {write_report_dir}.')

if verbose:
    print('Copying home page')
if not skip_html:
    shutil.copy(Path(index_dir, 'index.html'), Path(target_dir, 'index.html'))
shutil.copy(Path(index_dir, 'index.md'), Path(target_dir, 'index.md'))
stats['Home page file copied'] += 1

print('\nCopy summary:')
for label, count in stats.items():
    print(f'  {label}: {count}')
