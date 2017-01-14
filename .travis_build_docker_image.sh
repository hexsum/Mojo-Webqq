docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
docker build -f docker-image/Dockerfile -t $DOCKER_REPO docker-image
docker tag $DOCKER_REPO:latest $DOCKER_REPO:$TRAVIS_TAG
docker push $DOCKER_REPO