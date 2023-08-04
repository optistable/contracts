FROM node:16

# Create app directory
RUN mkdir /app
WORKDIR /app

# Bundle app source
COPY . .

# RUN rm yarn.lock

RUN yarn
