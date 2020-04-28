Set up using https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform

In addition to the services enabled in the article we'll need to enable others, like this:

```
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com
```