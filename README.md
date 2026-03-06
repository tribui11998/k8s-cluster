# k8s-cluster
k8s-cluster

# Information

Codespace  2-core • 8GB RAM • 32GB

```
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get update
sudo apt-get install ca-certificates gnupg curl software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible

wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get update && sudo apt-get install google-cloud-cli ansible terraform
```

Setup Google cloud
Create project, get project ID
Enable APIs serivces

```
https://learning.oreilly.com/interactive-lab/google-cloud-sandbox/9781098162948/



gcloud services enable \
  compute.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com

https://console.cloud.google.com/welcome?project=user-cifrgcupmaah

project=user-cifrgcupmaah
user=tribui2026@gmail.com
gcloud projects add-iam-policy-binding $project \
  --member="user:$user" \
  --role="roles/editor"
gcloud projects add-iam-policy-binding $project \
  --member="user:$user" \
  --role="roles/container.admin"
```

Login gcloud command

```
gcloud auth login
gcloud auth application-default login

gcloud config set project $project
```

Run terraform

```
terraform init
terraform plan
terraform apply --auto-approve
terraform destroy
```

Login VM

```
gcloud compute ssh my-vm --zone=asia-southeast1-a --project=$project

```