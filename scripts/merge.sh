git checkout --orphan latest_branch
git add .
git commit -am "Initial commit"
git branch -D main
git branch -m main
git push -f origin main

git tag -d latest
git tag latest
git push origin latest --force