# python-try
Template python repository

- devcontainer local python development
- dockerfile, image, container local testing
- Makefile, tooling local testing

## Main commands

Create devcontainer:
`Ctrl + Shift + P -> Dev Containers: Rebuild Container`

```sh
# add and use named commits - chore: | feat: | fix: | refactor: 
git ac "feat: new feature" && git push

## bumps version and push tags to remote (default -> patch version)
# !! runs build -> push pipeline to ghcr
# !! runs release pipeline to make release on github
make release # make release <patch/minor/major>

## Server live test, no docker
make live

## Build and run in docker container
make docker-build
```

### Debug image labels locally

```sh
IMAGE=ghcr.io/levarc-hub/python-try:$(git describe --tags --abbrev=0)
IMAGE_ID=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep $IMAGE | awk '{print $2}')
echo -e "\nIMAGE_ID: $IMAGE_ID\n"
docker inspect "$IMAGE_ID" --format='{{json .Config.Labels}}' | jq
```
