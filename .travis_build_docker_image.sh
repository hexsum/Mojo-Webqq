export TAG=${TRAVIS_TAG#v}
docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
docker build -f docker-image/Dockerfile -t $DOCKER_REPO:$TAG docker-image
docker tag $DOCKER_REPO:$TAG $DOCKER_REPO:latest
docker push $DOCKER_REPO