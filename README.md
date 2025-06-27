## 🧠 README.md - Laboratorio: Load Balancer con Alta Disponibilidad en Azure

### 🎯 Objetivo General
Aprender a implementar un **Load Balancer Público** en Azure con 2 máquinas virtuales Linux distribuidas en un Availability Set, usando buenas prácticas de etiquetado, seguridad y eficiencia de costos.

---

## ✅ ¿Qué aprenderás?
- Crear una red virtual (VNet) y subred
- Implementar 2 VMs con alta disponibilidad en un Availability Set
- Desplegar un **Load Balancer Público** y configurar reglas de tráfico
- Validar el funcionamiento del balanceador con `curl`, navegador y Azure Portal
- Automatizar la creación, verificación y eliminación de recursos con scripts

---

## 🧪 Requisitos
- Azure CLI o **Azure Cloud Shell**
- Suscripción activa de Azure (Freetier compatible)
- Conocimientos básicos de terminal Bash/Linux
- Acceso a navegador y/o terminal con `curl`

---

## 💸 Estimación de Costo
> ⚠️ Si ejecutas y eliminas todo en menos de 1 hora, el costo estimado será **menor a $0.10 USD**.

---

## 📂 Estructura del Repositorio

```bash
load_balancer_ha_2vms/
├── crear_lab_nlb.sh         # Script para crear toda la infraestructura
├── verificar_lab_nlb.sh     # Script para verificar conectividad y reglas
├── eliminar_lab_nlb.sh      # Script para eliminar toda la infraestructura
└── README.md                # Documentación detallada
```

---

## ⚙️ Descripción de los Scripts

### 🔧 crear_lab_nlb.sh
Crea todos los recursos necesarios:
- Grupo de recursos con etiquetas FinOps
- Red virtual y subred
- Availability Set
- 2 máquinas virtuales Ubuntu
- NSG con regla HTTP (puerto 80)
- IP pública
- Load Balancer + regla de tráfico + health probe
- Contenido personalizado en Nginx para identificar cada VM

> ⚠️ Ejecutar `az login` antes si no estás autenticado.

### 🔍 verificar_lab_nlb.sh
Realiza las siguientes acciones:
- Obtiene la IP pública del Load Balancer
- Ejecuta múltiples consultas `curl` para validar el tráfico distribuido entre las 2 VMs
- Verifica alternancia de respuestas (`Hola desde VM1`, `Hola desde VM2`, ...)

### 🗑 eliminar_lab_nlb.sh
- Solicita confirmación para evitar eliminaciones accidentales
- Elimina el grupo de recursos completo (y por tanto todos los componentes)
- No devuelve el prompt hasta que se eliminen todos los recursos
- Muestra mensajes informativos sobre el progreso de eliminación

---

## 🔎 Validación del Balanceador

### 🌐 Obtener la IP Pública
```bash
az network public-ip show -g rg-nlb-lab -n pip-nlb --query ipAddress -o tsv
```

### 🔁 Probar desde terminal (Linux/macOS/WSL)
```bash
for i in {1..6}; do curl http://<IP_PUBLICA>; echo ""; done
```

### 🌍 Probar desde navegador
Abre `http://<IP_PUBLICA>` en tu navegador varias veces o presiona F5 varias veces. Deberías ver:
```
Hola desde VM1
Hola desde VM2
Hola desde VM1
...
```

### 📊 Validación desde Azure Portal
1. Ir a **Load Balancer** → `lb-nlb`
2. Verifica:
   - Frontend IP Configuration: IP estática
   - Backend Pool: Ambas VMs conectadas
   - Health Probe: Estado `Succeeded`
   - Load Balancing Rule: Puerto 80 activo

---

## 🚀 Orden recomendado de ejecución paso a paso

### Paso 1: Iniciar sesión en Azure
```bash
az login
```

### Paso 2: Asignar permisos de ejecución y ejecutar los scripts en orden
```bash
chmod +x crear_lab_nlb.sh verificar_lab_nlb.sh eliminar_lab_nlb.sh

# Crear toda la infraestructura
./crear_lab_nlb.sh

# Verificar funcionamiento del balanceador
./verificar_lab_nlb.sh

# Eliminar todos los recursos (tras finalizar las pruebas)
./eliminar_lab_nlb.sh
```

> 💡 Ejecuta los comandos desde tu equipo local o desde Azure Cloud Shell.

---

## 📜 Código fuente de los scripts

### 🔧 crear_lab_nlb.sh
```bash
#!/bin/bash

set -e

RG="rg-nlb-lab"
LOC="eastus"
VNET="vnet-nlb"
SUBNET="subnet-nlb"
VM_SIZE="Standard_B1s"
USERNAME="azureuser"
PASSWORD="Password1234"
AVSET="avset-nlb"

az login

az group create -n $RG -l $LOC --tags autor=gmtech proyecto=lab_nlb_ha

az network vnet create -g $RG -n $VNET --address-prefix 10.20.0.0/16 \
  --subnet-name $SUBNET --subnet-prefix 10.20.1.0/24

az vm availability-set create -n $AVSET -g $RG \
  --platform-fault-domain-count 2 --platform-update-domain-count 2

az network nsg create -g $RG -n nsg-nlb
az network nsg rule create -g $RG --nsg-name nsg-nlb -n Allow80 \
  --priority 1000 --access Allow --protocol Tcp --direction Inbound \
  --destination-port-range 80

az network public-ip create -g $RG -n pip-nlb --sku Basic --allocation-method Static

az network lb create -g $RG -n lb-nlb --sku Basic --public-ip-address pip-nlb \
  --frontend-ip-name lb-front --backend-pool-name lb-backend

az network lb rule create -g $RG --lb-name lb-nlb -n lb-rule-http \
  --backend-pool-name lb-backend --backend-port 80 --frontend-ip-name lb-front \
  --frontend-port 80 --protocol Tcp --probe-name http-probe

az network lb probe create -g $RG --lb-name lb-nlb -n http-probe \
  --protocol Http --port 80 --path /

for i in 1 2; do
  az vm create \
    --resource-group $RG \
    --name vm$i-nlb \
    --image Ubuntu2204 \
    --size $VM_SIZE \
    --admin-username $USERNAME \
    --admin-password $PASSWORD \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --nsg nsg-nlb \
    --availability-set $AVSET \
    --no-wait

done

sleep 90

for i in 1 2; do
  NIC_ID=$(az vm show -g $RG -n vm$i-nlb --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  az network nic ip-config address-pool add \
    --address-pool lb-backend \
    --ip-config-name ipconfig1 \
    --nic-name $(basename $NIC_ID) \
    --resource-group $RG \
    --lb-name lb-nlb \
    --backend-pool-name lb-backend

  az vm run-command invoke -g $RG -n vm$i-nlb \
    --command-id RunShellScript \
    --scripts "echo 'Hola desde VM$i' | sudo tee /var/www/html/index.html && sudo apt update && sudo apt install nginx -y && sudo systemctl start nginx"
done

IP_PUBLICA=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ Accede desde navegador o curl: http://$IP_PUBLICA"
```

### 🔍 verificar_lab_nlb.sh
```bash
#!/bin/bash

RG="rg-nlb-lab"
IP=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)

echo "🌐 IP Pública del Load Balancer: $IP"

echo "🔁 Verificando balanceo (4 consultas)..."
for i in {1..4}; do
  curl http://$IP
  echo ""
done
```

### 🗑 eliminar_lab_nlb.sh
```bash
#!/bin/bash

RG="rg-nlb-lab"

echo "⚠️ Vas a eliminar todos los recursos del laboratorio..."
echo "⏳ Si lo usaste menos de 1h, el costo estimado es < $0.10 USD"
echo "¿Continuar? (s/n): "
read confirm

if [[ "$confirm" != "s" ]]; then
  echo "❌ Cancelado."
  exit 1
fi

az group delete -n $RG --yes --no-wait

while az group exists -n $RG; do
  echo "⌛ Eliminando grupo de recursos..."
  sleep 10
done

echo "✅ Laboratorio eliminado."
```

---

## 🧑‍🏫 Autor
Jose Garagorry — Instructor Especialista en Azure Networking

---

🎓 Este laboratorio está optimizado para estudiantes y profesionales que deseen comprender de forma práctica:
- Alta disponibilidad en Azure
- Balanceo de carga con bajo costo
- Automatización de infraestructura
- Validación efectiva desde CLI y Portal

> Incluye buenas prácticas de **etiquetado**, principios **FinOps**, y una estructura didáctica para principiantes y autodidactas.
