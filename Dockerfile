FROM swiftlang/swift:nightly-5.5-amazonlinux2
RUN yum -y install git \
  jq \
  tar \
  zip

WORKDIR /build-lambda

RUN mkdir -p /Sources/CompilerLambda
RUN mkdir -p /Tests/CompilerLambda

ADD /Sources/ ./Sources
ADD /Tests/ ./Tests/

COPY Package.swift .

RUN cd /build-lambda && swift build --product CompilerLambda -c release -Xswiftc -static-stdlib

RUN mkdir -p /var/task/
RUN cp .build/release/CompilerLambda /var/task/CompilerLambda
WORKDIR /var/task
RUN ln -s CompilerLambda bootstrap

RUN chmod 755 ./bootstrap
RUN chmod 755 ./CompilerLambda

CMD ["/var/task/CompilerLambda"]
