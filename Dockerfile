ARG RUNTIME=nodejs12.x
ARG TERRAFORM=latest

# --- Lock NodeJS packages

FROM lambci/lambda:build-${RUNTIME} AS lock

# Lock events module
WORKDIR /var/task/events
COPY events .
RUN npm install --production

# Lock invite module
WORKDIR /var/task/invite
COPY invite .
RUN npm install --production

# Lock mods module
WORKDIR /var/task/mods
COPY mods .
RUN npm install --production

# Lock welcome module
WORKDIR /var/task/welcome
COPY welcome .
RUN npm install --production

WORKDIR /var/task/

# --- Zip Lambda packages

FROM lambci/lambda:build-${RUNTIME} AS zip
COPY --from=lock /var/task/ .
RUN mkdir /var/task/dist

# Zip events package
WORKDIR /var/task/events
RUN zip -9r /var/task/dist/events.zip node_modules *.js *.json

# Build invite module
WORKDIR /var/task/invite
RUN zip -9r /var/task/dist/invite.zip node_modules *.js *.json

# Build mods module
WORKDIR /var/task/mods
RUN zip -9r /var/task/dist/mods.zip node_modules *.js *.json

# Build welcome module
WORKDIR /var/task/welcome
RUN zip -9r /var/task/dist/welcome.zip node_modules *.js *.json

WORKDIR /var/task/

# --- Terraform

FROM hashicorp/terraform:${TERRAFORM} AS plan
WORKDIR /var/task/
COPY *.tf /var/task/
COPY --from=zip /var/task/ .
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION=us-east-1
ARG AWS_SECRET_ACCESS_KEY
RUN terraform init
RUN terraform fmt -check
ARG TF_VAR_VERSION
RUN terraform plan -out terraform.zip
CMD ["apply", "terraform.zip"]
