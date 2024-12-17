# kong-playground
minikube addons enable metrics-server

echo "Deleting Helm charts"
#delete kong releases
helm del kongcp -n cp
helm del kongpg -n pg
helm del kongdp -n dp
helm del redis -n rd
helm del certmanager -n cm
helm del prometheus -n mt
helm del loki -n mt
helm del jaegeroperator -n mt

echo "Deleting Namespaces"
#delete k8s namespaces
kubectl delete namespace cp
kubectl delete namespace dp
kubectl delete namespace pg
kubectl delete namespace rd
kubectl delete namespace cm
kubectl delete namespace mt

# uncomment delete the namespace and helm charts and stop
if [ $1 == "stop" ]
then
    echo "Cleanup complete."
    echo "Exiting."
    exit
else
    echo "Cleanup complete."
    echo "Starting new."
fi

echo "Creating Namespaces"
#create k8s namespaces
kubectl create namespace cp
kubectl create namespace dp
kubectl create namespace pg
kubectl create namespace rd
kubectl create namespace cm
kubectl create namespace mt

echo "Creating Keycloak"
kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes/keycloak.yaml

echo "Creating secrets"
#create the k8s secrets
#CP secret
kubectl create secret generic kong-enterprise-postgres-password --from-literal=password=kong -n cp
#kubectl create secret generic kong-ca-cert --from-file=./ca_cert/ca-cert.pem -n cp
#kubectl create secret tls kong-cp-cert --cert=./cp_cert/control-plane.crt --key=./cp_cert/control-plane.key -n cp

kubectl create secret generic kong-session-conf --from-file=./conf/admin_gui_session_conf --from-file=./conf/portal_session_conf -n cp
kubectl create secret generic kong-auth-conf --from-file=./conf/admin_gui_auth_conf --from-file=./conf/portal_auth_conf -n cp
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password="password" -n cp
kubectl create secret generic kong-enterprise-license --from-file=license=./license/kong-license.json -n cp

#DP secret
# license push from admin api -> http POST :8001/licenses payload='$LICENSE_DATA'
kubectl create secret generic kong-enterprise-license --from-file=license=./license/kong-license.json -n dp
# could be replace with own secret
kubectl create secret generic kong-enterprise-superuser-password --from-literal=password="password" -n dp
#kubectl create secret generic kong-ca-cert --from-file=./ca_cert/ca-cert.pem -n dp
#kubectl create secret tls kong-dp-cert --cert=./dp_cert/data-plane.crt --key=./dp_cert/data-plane.key -n dp

echo "Install helm charts"
#install the helm charts
#https://aws.amazon.com/blogs/security/tls-enabled-kubernetes-clusters-with-acm-private-ca-and-amazon-eks-2/
#helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo add kong https://charts.konghq.com
helm repo add minio https://helm.min.io/
helm repo update

helm install certmanager jetstack/cert-manager --set installCRDs=true -n cm
#helm install awspca awspca/aws-privateca-issuer -n cm
#kubectl apply -f ./certs/issuerAws.yaml -n cm
kubectl apply -f ./certs/selfSignedCA.yaml -n cm
kubectl apply -f ./certs/CP_CA.yaml -n cp
kubectl apply -f ./certs/DP_CA.yaml -n dp

helm install prometheus prometheus-community/kube-prometheus-stack --values=./charts/promKubes_values.yaml -n mt
#helm install statsd prometheus-community/prometheus-statsd-exporter --values=./charts/statsd_values.yaml -n dp
helm install loki grafana/loki-stack --values=./charts/loki_values.yaml -n mt
helm install miniobackup minio/minio --set accessKey=myaccesskey,secretKey=mysecretkey -n mt
helm install jaegeroperator jaegertracing/jaeger-operator --set rbac.clusterRole=true -n mt
helm install kongpg bitnami/postgresql --values=./charts/pg_values.yaml -n pg
helm install kongcp kong/kong --values=./charts/cp_values.yaml -n cp
helm install kongdp kong/kong --values=./charts/dp_values.yaml -n dp
helm install redis bitnami/redis --values=./charts/redis_values.yaml -n rd

sleep 10
kubectl apply -f monitoring.yaml
sleep 10
kubectl expose service prometheus-operated --name prometheus-operated-lb -n dp

export JAEGER_URL=$(kubectl get svc jaeger-query -o jsonpath='{.status.loadBalancer.ingress[].ip}' -n mt)
echo Jaeger URL: http://$JAEGER_URL:16686

deck sync -s kong.yaml
