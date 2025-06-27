## 🧠 README.md - Laboratorio: Load Balancer con Alta Disponibilidad en Azure

### 🎯 Objetivo General
Aprender a implementar un **Load Balancer Público** en Azure con 2 VMs Linux distribuidas en un Availability Set, siguiendo buenas prácticas de etiquetado, seguridad y costos bajos.

---

## ✅ ¿Qué aprenderás?
- Crear redes virtuales y subredes en Azure (VNet + Subnet)
- Implementar dos máquinas virtuales con alta disponibilidad
- Desplegar un **Load Balancer Público** y configurar reglas de tráfico
- Validar el funcionamiento del balanceador desde CLI y navegador
- Automatizar todo con scripts (crear, verificar, eliminar)

---

## 🧪 Requisitos
- Azure CLI o usar **Azure Cloud Shell** (recomendado)
- Suscripción activa en Azure (puede ser Freetier)
- Conocimientos básicos de terminal Bash o Linux
- Navegador o `curl` para validar conectividad

---

## 💸 Estimación de Costo
> ⚠️ Si ejecutas el laboratorio, lo pruebas y eliminas todo en menos de **1 hora**, el costo estimado será **menor a $0.10 USD**.

---

## 📂 Estructura del Repositorio

```bash
load_balancer_ha_2vms/
├── crear_lab_nlb.sh         # Crea toda la infraestructura
├── verificar_lab_nlb.sh     # Verifica conectividad y reglas
├── eliminar_lab_nlb.sh      # Elimina la infraestructura (con espera y confirmación)
└── README.md                # Este archivo
```

---

## ⚙️ Scripts incluidos

### 🔧 crear_lab_nlb.sh
Crea el grupo de recursos, red virtual, subred, Availability Set, VMs, NSG, IP pública, Load Balancer, reglas, probe y contenido personalizado en Nginx.

> Se recomienda usar `az login` antes de ejecutar este script.

### 🔍 verificar_lab_nlb.sh
Obtiene la IP pública del Load Balancer y realiza 4 consultas usando `curl` para verificar que el tráfico se distribuye entre ambas VMs (respuestas alternadas).

### 🗑 eliminar_lab_nlb.sh
Elimina todo el grupo de recursos del laboratorio.
- Solicita confirmación antes de ejecutar.
- No regresa el prompt hasta confirmar que todo fue eliminado.

---

## 🔎 Validar funcionamiento del Load Balancer

### 🌐 Obtener IP Pública del Load Balancer
```bash
az network public-ip show -g rg-nlb-lab -n pip-nlb --query ipAddress -o tsv
```

### 🔁 Validar balanceo con curl o navegador
```bash
curl http://<IP_PUBLICA>
```
O abre la IP en tu navegador. Deberías ver alternadamente:
```
Hola desde VM1
Hola desde VM2
Hola desde VM1
...
```

Esto confirma que el tráfico se balancea correctamente entre las dos máquinas.

### 📊 Validar desde el Portal de Azure
1. Ve al recurso **Load Balancer** → `lb-nlb`
2. Revisa:
   - **Frontend IP Configuration** (IP estática)
   - **Backend Pool** → Debe haber 2 VMs conectadas
   - **Health Probe** → Estado debe ser `Succeeded`
   - **Load Balancing Rules** → Puerto 80 configurado

---

## 🚀 Ejecución paso a paso

```bash
az login
chmod +x crear_lab_nlb.sh verificar_lab_nlb.sh eliminar_lab_nlb.sh
./crear_lab_nlb.sh
./verificar_lab_nlb.sh
./eliminar_lab_nlb.sh
```

---

## 🧑‍🏫 Autor
Jose Garagorry - Instructor Azure Networking

---

🎓 Este laboratorio está diseñado con buenas prácticas de **etiquetado**, enfoque **FinOps**, y validaciones que ayudan a comprender el impacto de un Load Balancer en un entorno de alta disponibilidad real.

```

---

## ⚙️ Scripts incluidos

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

echo "🔐 Iniciando sesión..."
az login

echo "🔧 Creando grupo de recursos..."
az group create -n $RG -l $LOC --tags autor=gmtech proyecto=lab_nlb_ha

echo "🌐 Creando VNet y subred..."
az network vnet create -g $RG -n $VNET --address-prefix 10.20.0.0/16 \
  --subnet-name $SUBNET --subnet-prefix 10.20.1.0/24

echo "🧱 Creando Availability Set..."
az vm availability-set create -n $AVSET -g $RG --platform-fault-domain-count 2 --platform-update-domain-count 2

echo "🔒 Creando NSG con reglas..."
az network nsg create -g $RG -n nsg-nlb
az network nsg rule create -g $RG --nsg-name nsg-nlb -n Allow80 --priority 1000 \
  --access Allow --protocol Tcp --direction Inbound --destination-port-range 80

echo "🌐 Creando IP pública..."
az network public-ip create -g $RG -n pip-nlb --sku Basic --allocation-method Static

echo "🧱 Creando Load Balancer..."
az network lb create -g $RG -n lb-nlb --sku Basic --public-ip-address pip-nlb \
  --frontend-ip-name lb-front --backend-pool-name lb-backend

echo "⚙️ Configurando regla de balanceo (HTTP 80)..."
az network lb rule create -g $RG --lb-name lb-nlb -n lb-rule-http \
  --backend-pool-name lb-backend --backend-port 80 --frontend-ip-name lb-front \
  --frontend-port 80 --protocol Tcp --probe-name http-probe

echo "📡 Agregando probe para salud HTTP..."
az network lb probe create -g $RG --lb-name lb-nlb -n http-probe \
  --protocol Http --port 80 --path /

for i in 1 2; do
  echo "🖥️ Creando VM$i..."
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
  echo "🔁 Agregando NIC de VM$i al backend del LB..."
  NIC_ID=$(az vm show -g $RG -n vm$i-nlb --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  az network nic ip-config address-pool add \
    --address-pool lb-backend \
    --ip-config-name ipconfig1 \
    --nic-name $(basename $NIC_ID) \
    --resource-group $RG \
    --lb-name lb-nlb \
    --backend-pool-name lb-backend

  echo "📝 Agregando contenido a VM$i..."
  az vm run-command invoke -g $RG -n vm$i-nlb \
    --command-id RunShellScript \
    --scripts "echo 'Hola desde VM$i' | sudo tee /var/www/html/index.html && sudo apt update && sudo apt install nginx -y && sudo systemctl start nginx"
done

IP_PUBLICA=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ Laboratorio creado. Accede desde navegador o curl: http://$IP_PUBLICA"
```

### 🔍 verificar_lab_nlb.sh
```bash
#!/bin/bash

RG="rg-nlb-lab"

echo "🌐 Verificando IP pública del Load Balancer..."
IP=$(az network public-ip show -g $RG -n pip-nlb --query ipAddress -o tsv)
echo "✅ IP Pública: $IP"

echo "🔁 Probando balanceo con curl (x4)..."
for i in {1..4}; do
  curl http://$IP
  echo ""
done
```

### 🗑 eliminar_lab_nlb.sh
```bash
#!/bin/bash

RG="rg-nlb-lab"

echo "⚠️ ¡Eliminarás todos los recursos del laboratorio NLB!"
echo "⏳ Si lo usaste menos de 1h, el costo estimado es menor a $0.10 USD"
echo "¿Continuar? (s/n): "
read confirm

if [[ "$confirm" != "s" ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

az group delete -n $RG --yes --no-wait

while az group exists -n $RG; do
  echo "⏳ Esperando que se elimine el grupo de recursos..."
  sleep 10
done

echo "✅ Laboratorio eliminado."
```

---

## 🚀 Ejecución Rápida

```bash
az login
chmod +x crear_lab_nlb.sh verificar_lab_nlb.sh eliminar_lab_nlb.sh
./crear_lab_nlb.sh
./verificar_lab_nlb.sh
./eliminar_lab_nlb.sh
```

---

## 🧑‍🏫 Autor
Jose Garagorry - Instructor Azure Networking
