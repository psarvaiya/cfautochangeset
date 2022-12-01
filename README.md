
# Introduction

This repo automates the execution of change sets on PR approval to main/master branch

## How to ??

### 1. Configure AWS credentials

Create a role to assume OIDC identity provider

We have already added a cloudformation template `oidc-cloudformation.yaml` 

Execute on AWS cloudformation, it will create necessary resources.

1. Provide the name of your GitHub organization and repo

![image](https://user-images.githubusercontent.com/68551613/205029222-118f9f3b-7a2b-4d79-b8c0-5d2291e6f5c6.png)

2. OIDC provider is created

![image](https://user-images.githubusercontent.com/68551613/205029255-10d9ed89-b236-4f98-b7ef-deee42740e14.png)

3. Role is created. You can add necessary permission to the role, as per the resources getting created by cloudformation.

![image](https://user-images.githubusercontent.com/68551613/205029310-21e31405-c000-4032-a554-4b9f0a0afa2d.png)

### 2. Add region and role as secret

`AWS_REGION` and `AWS_ROLE`

![image](https://user-images.githubusercontent.com/68551613/205030498-9dcffc00-7577-44d8-8f9d-3939fe360c38.png)

### 3. Update the parameters as required in `parameters-dev.json`

```
[
    {
        "ParameterKey":"S3BucketName",
        "ParameterValue":"my-s3-bucket"
    },
    {
        "ParameterKey":"SelectStage",
        "ParameterValue":"dev"
    }
]


```

### 4. Provide the name of change sets in `changeset.name`

**NOTE** Added`cf-template.yaml` for reference. Automation CI workflow is present at `.github/workflows/ci.yaml`

### 5. You can also download the artifacts of every run

![image](https://user-images.githubusercontent.com/68551613/205032781-e7535590-b11c-4b43-a24f-577153638d61.png)



