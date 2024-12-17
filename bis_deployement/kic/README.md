kubectl create namespace kic

kubectl create secret generic kong-enterprise-license --from-file=license=./license/kong-license.json -n kic


helm install kongkic kong/ingress --values=./bis_deployement/kic/kong_kic.yaml -n kic


kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml

kubectl apply -f bis_deployement/kic/kic_config.yaml 


kubectl apply -f https://docs.konghq.com/assets/kubernetes-ingress-controller/examples/echo-service.yaml => create echo service 


echo "
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: echo
 annotations:
   konghq.com/strip-path: 'true'
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /echoreply
   backendRefs:
   - name: echo
     kind: Service
     port: 1027
" | kubectl apply -f -



Konnect KIC:

kubectl create secret tls konnect-client-tls -n kic --cert=./bis_deployement/kic/tls.crt --key=./bis_deployement/kic/tls.key

Uncomment the Konnect part and run:

helm upgrade kongkic kong/ingress --values=./bis_deployement/kic/kong_kic.yaml -n kic         