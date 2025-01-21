# Default commit message
commit_msg="Minor adjustments"

# Check if the first argument is provided
if [ -n "$1" ]; then
  commit_msg="$1"
fi

git add .
git commit -m "$commit_msg"
git push origin main

git tag -d latest
git tag latest
git push origin latest --force