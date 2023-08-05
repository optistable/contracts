# Docker container built using this Dockerfile
# can be published to the public docker registry
# But before running the container it must be configured to provide
# the node config through environment variables

ARG VERSION
FROM redstone-monorepo:${VERSION}

WORKDIR /app/packages/oracle-node

RUN yarn
RUN yarn build

# Setting production env variables
ENV ENABLE_JSON_LOGS=true
ENV ENABLE_PERFORMANCE_TRACKING=true
ENV PRINT_DIAGNOSTIC_INFO=true
ENV MANIFEST_REFRESH_INTERVAL=120000
ENV ARWEAVE_KEYS_FILE_PATH=
ENV ARWEAVE_KEYS_JWK=
ENV OVERRIDE_MANIFEST_USING_FILE=
ENV ECDSA_PRIVATE_KEY=
ENV TWELVE_DATA_RAPID_API_KEY=
ENV USE_NEW_SIGNING_AND_BROADCASTING=false

# Exposing 8080 port for health checks
EXPOSE 8080

# Running redstone node
CMD yarn start:prod
