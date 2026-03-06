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


gcloud compute scp localfile.txt my-vm:~/remotefile.txt --zone=asia-southeast1-a --project=$project
gcloud compute scp --recurse local-folder my-vm:~/remote-folder --zone=asia-southeast1-a --project=$project
```

Join cluster
```
sudo kubeadm join 10.0.1.3:6443 --token y69pby.a7uarjo319byut1f --discovery-token-ca-cert-hash sha256:99c6a044dc98906cda6df71b1f39f60c0dde9df89f9d482390b89dce2dea217b 

You can now join any number of control-plane nodes running the following command on each as root:

  kubeadm join 10.0.1.3:6443 --token 7aa6i0.gdj41ofvzdsxykpy \
        --discovery-token-ca-cert-hash sha256:99c6a044dc98906cda6df71b1f39f60c0dde9df89f9d482390b89dce2dea217b \
        --control-plane --certificate-key c99286b6b2dde1940c8720ce5b7a0b4d3b27799f999ef3169669d659e69b70c6

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.1.3:6443 --token 7aa6i0.gdj41ofvzdsxykpy \
        --discovery-token-ca-cert-hash sha256:99c6a044dc98906cda6df71b1f39f60c0dde9df89f9d482390b89dce2dea217b

kubectl label node my-vm-2.asia-southeast1-b.c.user-cifrgcupmaah.internal node-role.kubernetes.io/worker=worker

``

Deploy demo-app

```
# 1. namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo

---
# 2. deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  namespace: demo
  labels:
    app: nginx-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5

---
# 3. configmap.yaml - Custom HTML page
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
  namespace: demo
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>K8s Demo</title></head>
    <body style="font-family:sans-serif; text-align:center; padding:50px;">
      <h1>Hello from Kubernetes!</h1>
      <p>Nginx is running on K8s cluster</p>
      <p>Pod: <!-- hostname will show pod name --></p>
    </body>
    </html>

---
# 4. service.yaml - Expose qua NodePort
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
  namespace: demo
spec:
  type: NodePort
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

```
kubectl get pods -n demo

```