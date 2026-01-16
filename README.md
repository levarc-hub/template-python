# python-try
Template python repository

- devcontainer local python development
- dockerfile, image, container local testing
- Makefile, tooling local testing

## Main dev commands
```sh
# install deps if needed
pip install -r src/requirements.txt

# CI test
make verify lint test check-build

# add and commit files: 
git add -A && git commit -m "new signed commit" && git push

## bumps version and push tags to remote (default -> patch version)
# !! runs build -> push pipeline to ghcr
# !! runs release pipeline to make release on github
make release # make release <patch/minor/major>

## Server local test
python src/server.py

## Build and run dock
make docker-build
```

## Debug image labels locally

```sh
IMAGE=ghcr.io/levarc-hub/python-try:$(git describe --tags --abbrev=0)
IMAGE_ID=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep $IMAGE | awk '{print $2}')
echo -e "\nIMAGE_ID: $IMAGE_ID\n"
docker inspect "$IMAGE_ID" --format='{{json .Config.Labels}}' | jq
```