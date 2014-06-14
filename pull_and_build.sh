echo "\e[33m**************************\e[39m"
echo "\e[33m*  Pulling last sources  *\e[39m"
echo "\e[33m**************************\e[39m"
if git pull; then
  echo "\e[32mPulling last sources: OK\e[39m"
  echo "\e[33m*************************\e[39m"
  echo "\e[33m*  Bundle installation  *\e[39m"
  echo "\e[33m*************************\e[39m"
  if bundle install; then
    echo "\e[32mBundle installation: OK\e[39m"
    echo "\e[33m*************************\e[39m"
    echo "\e[33m*  Building blog files  *\e[39m"
    echo "\e[33m*************************\e[39m"
    if jekyll build; then
      echo "\e[32mBuilding blog files: OK\e[39m"
      echo "\e[32m*************************\e[39m"
      echo "\e[32m*  Deployment complete  *\e[39m"
      echo "\e[32m*************************\e[39m"
    else
      echo "\e[33m********************************\e[39m"
      echo "\e[33m*  Failed to build blog files  *\e[39m"
      echo "\e[33m*  Aborting...                 *\e[39m"
      echo "\e[33m********************************\e[39m"
    fi
  else
    echo "\e[33m******************************\e[39m"
    echo "\e[33m*  Failed to install bundle  *\e[39m"
    echo "\e[33m*  Aborting...               *\e[39m"
    echo "\e[33m******************************\e[39m"
  fi
else
  echo "\e[33m*********************************\e[39m"
  echo "\e[33m*  Failed to Pull last sources  *\e[39m"
  echo "\e[33m*  Aborting...                  *\e[39m"
  echo "\e[33m*********************************\e[39m"
fi
