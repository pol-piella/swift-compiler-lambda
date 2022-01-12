FROM swiftlang/swift:nightly-amazonlinux2
ARG USER_ID
ARG GROUP_ID
RUN groupadd -f --gid $GROUP_ID user
RUN useradd --uid $USER_ID --gid $GROUP_ID -c '' user
USER user