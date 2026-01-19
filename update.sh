#!/bin/bash

echo "Updating forecasts"
cd /Users/chrisfairless/Library/CloudStorage/OneDrive-Personal/Projects/UNU/idmc/forecast/displacement_forecast
/usr/local/Caskroom/miniforge/base/envs/idmc_forecast/bin/python process_all_forecasts.py

cd /Users/chrisfairless/Library/CloudStorage/OneDrive-Personal/Projects/UNU/idmc/forecast/displacement_forecast_page
git pull
/usr/local/Caskroom/miniforge/base/envs/idmc_forecast/bin/python copy_over_outputs.py

git add *
git commit -m "Manual update"
git push
echo "Forecasts updated"
