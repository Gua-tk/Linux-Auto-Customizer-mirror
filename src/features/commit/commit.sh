
commit()
{
  messag="$@"
  while [ -z "$messag" ]; do
    read -p "Add message: " messag
  done
  git commit -am "$messag"
}
if [ -f "€{BASH_COMPLETIONS_PATH}" ]; then
  source "€{BASH_COMPLETIONS_PATH}"
  __git_complete commit _git_commit
fi
