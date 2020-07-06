[General Setup](../README.md)

# Overview

The GCP modules will create a new project and then build the infrastructure within that project.  On
cleanup, the infrastructure and related project will be destroyed.  Note that this uses a service 
account in a master project within the same organization.

Set up by following https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform

# Requirements

You'll need to have an account with an organization.  Note, many GCP users will not have an
organization.  If that's the case, then create a project manually and create a variable to hold
the project ID.  Pass it to modules in the same fashion as is done if it were createde dynamically.

# Environment

This is covered in the article referenced above.  The key configuration is in environment variables
are shown below.

TF_CREDS=/Users/dan/.config/gcloud/terraform-admin-dan.json
TF_ADMIN=terraform-admin-dan
TF_VAR_billing_account=[my account]
TF_VAR_org_id=[my org ID]


In addition to the services enabled in the article we'll need to enable the services below.

```
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services enable container.googleapis.com
```

See init.sh for details.

The service account will also need additional privileges for GKE:

```
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/container.admin


gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/compute.admin

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectIamAdmin
```