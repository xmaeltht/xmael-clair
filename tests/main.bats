#!/usr/bin/env bats

load ../common

@test "010 Image is present and healthy" {
    docker image inspect ${maintainer}/${imagename}
}

@test "030 Test Compose the environment" {
    cd test-compose && ./compose.sh && docker-compose down
}


@test "070 There are no known security vulnerabilities" {
    ./tests/clairscan.sh ${maintainer}/${imagename}:latest
}
