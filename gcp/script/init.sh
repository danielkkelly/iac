gcloud services enable \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    iam.googleapis.com \
    oslogin.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com \
    container.googleapis.com

gcloud iam service-accounts add-iam-policy-binding \
  terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com \
  --member=user:$GOOGLE_USER\
  --role=roles/iam.serviceAccountUser`