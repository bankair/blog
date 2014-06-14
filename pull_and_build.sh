echo "**************************"
echo "*  Pulling last sources  *"
echo "**************************"
if git pull; then
  echo "Pulling last sources: OK"
  echo "*************************"
  echo "*  Bundle installation  *"
  echo "*************************"
  if bundle install; then
    echo "Bundle installation: OK"
    echo "*************************"
    echo "*  Building blog files  *"
    echo "*************************"
    if jekyll build; then
      echo "Building blog files: OK"
      echo "*************************"
      echo "*  Deployment complete  *"
      echo "*************************"
    else
      echo "********************************"
      echo "*  Failed to build blog files  *"
      echo "*  Aborting...                 *"
      echo "********************************"
    fi
  else
    echo "******************************"
    echo "*  Failed to install bundle  *"
    echo "*  Aborting...               *"
    echo "******************************"
  fi
else
  echo "*********************************"
  echo "*  Failed to Pull last sources  *"
  echo "*  Aborting...                  *"
  echo "*********************************"
fi
