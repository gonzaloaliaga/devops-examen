Despliegue devops-examen en EKS (namespace 'devops')

1) Configurar kubectl contra tu cluster:
   aws eks update-kubeconfig --region us-east-1 --name <NOMBRE_TU_CLUSTER>

2) Aplicar namespace:
   kubectl apply -f namespace.yaml

3) Aplicar recursos de base de datos:
   kubectl apply -f mysql-secret.yaml
   kubectl apply -f mysql-deployment.yaml
   kubectl apply -f mysql-service.yaml

4) Aplicar backend:
   kubectl apply -f backend-deployment.yaml
   kubectl apply -f backend-service.yaml

5) Aplicar frontend:
   kubectl apply -f frontend-deployment.yaml
   kubectl apply -f frontend-service.yaml

6) Verificar:
   kubectl get pods -n devops
   kubectl get svc devops-frontend -n devops

Copias el EXTERNAL-IP (DNS del ELB) → lo abres en el navegador→ deberías ver la página de Devops (Despachos y ventas) ������

Nota: Si te da error, y sale el pod con estado Pending (valida correctamente la configuración de la Actividad 1 – paso 4).

