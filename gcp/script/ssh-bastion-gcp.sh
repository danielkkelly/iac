#!/bin/bash

gcloud compute ssh $(terraform output bastion_instance_id) --project $(terraform output project_id)
