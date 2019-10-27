ARG RUNTIME=nodejs10.x
ARG TERRAFORM=latest

# --- Build Lambda packages

FROM lambci/lambda:build-${RUNTIME} AS build
COPY . .

# Build events module
WORKDIR /var/task/events
RUN npm install --production
RUN zip -r package.zip node_modules *.js *.json

# Build invite module
WORKDIR /var/task/invite
RUN npm install --production
RUN zip -r package.zip node_modules *.js *.json

# Build mods module
WORKDIR /var/task/mods
RUN npm install --production
RUN zip -r package.zip node_modules *.js *.json

# Build welcome module
WORKDIR /var/task/welcome
RUN npm install --production
RUN zip -r package.zip node_modules *.js *.json

WORKDIR /var/task/

# --- Terraform
FROM hashicorp/terraform:${TERRAFORM} AS plan
WORKDIR /var/task/
COPY --from=build /var/task/ .
ARG AWS_ACCESS_KEY_ID
ARG AWS_DEFAULT_REGION=us-east-1
ARG AWS_SECRET_ACCESS_KEY
ARG TF_VAR_release
RUN terraform init
RUN terraform plan -out terraform.zip
CMD ["apply", "terraform.zip"]
