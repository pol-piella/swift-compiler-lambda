# CompilerLambda

## Build and Deploy

```
docker build . -t compiler-lambda --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)
docker run \
    --rm \
    --volume "$(pwd)/:/src" \
    --workdir "/src/" \
    compiler-lambda \
    swift build --product CompilerLambda -c release -Xswiftc -static-stdlib
./package.sh CompilerLambda
```
