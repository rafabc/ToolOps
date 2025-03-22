# date=$(date)
# echo $date > README.md

git status


git add .
git commit -m "Autocommit push.sh"
git push origin develop

git checkout main
git merge develop
git push origin main

git checkout develop