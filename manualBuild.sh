docker build --pull --tag=tier/grouper:latest . \

if [[ "$OSTYPE" == "darwin"* ]]; then
  say build complete
fi
