# ☁️ Azure HA Load Balancer con 2 VMs Linux – Optimizado para FinOps 💰

<p align="center">
  <img src="https://img.shields.io/badge/Azure-blue?style=for-the-badge&logo=microsoftazure&logoColor=white" alt="Azure Badge">
  <img src="https://img.shields.io/badge/Bash-black?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash Badge">
  <img src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="Ubuntu Badge">
  <img src="https://img.shields.io/badge/Licencia-MIT-green.svg?style=for-the-badge" alt="Licencia MIT">
</p>

Este proyecto despliega un **frontend web de alta disponibilidad y bajo coste en Azure**. Utiliza un **Load Balancer Standard** y **dos VMs Linux (Ubuntu 22.04 LTS)**. Todo está automatizado con scripts de **Bash** y la **CLI de Azure**, siguiendo las mejores prácticas de FinOps y seguridad.

---

## 🎯 Propósito

El objetivo es crear una infraestructura web resiliente y económica, ideal para demos, laboratorios o entornos de producción ligeros. La automatización garantiza un despliegue y una destrucción rápidos y fiables, evitando costes inesperados.

---

## 🏗️ Arquitectura

El tráfico de Internet es dirigido a través de una IP pública hacia un Load Balancer Standard, que distribuye la carga entre dos máquinas virtuales en diferentes zonas de disponibilidad para garantizar la alta disponibilidad.

🌐 Internet → 🔗 IP Pública → ⚖️ Standard Load Balancer
↙︎             ↘︎
🖥️ VM-01 (AZ 1)   🖥️ VM-02 (AZ 2)


### **Componentes y Justificación FinOps**

| Componente | SKU / Tamaño | Justificación de Coste (FinOps) |
| :--- | :--- | :--- |
| Máquina Virtual (VM) | `Standard_B1s` | El tamaño "burstable" más económico para demos productivas. |
| Disco del SO | `Standard SSD 64 GiB` | Más barato que Premium, suficiente para contenido web estático. |
| Balanceador de Carga | `Standard (Z-redundant)` | La opción multi-AZ más asequible. |
| IP Pública | `Standard` | Necesaria para el frontend y con redundancia de zona. |

---

## 🚀 Guía Rápida

### **1. Prerrequisitos**

* **Azure CLI** ≥ 2.60 (`az version`)
* **Bash** 4+ (se recomienda WSL 2 con Ubuntu 24.04)
* `jq` y `curl` instalados.
* Rol de **Contribuidor** en la suscripción de Azure.

### **2. Pasos de Despliegue**

```bash
# 1. Clonar el repositorio
git clone [https://github.com/jgaragorry/Load_Balancer_Ha_2vms.git](https://github.com/jgaragorry/Load_Balancer_Ha_2vms.git)
cd Load_Balancer_Ha_2vms

# 2. Iniciar sesión en Azure y configurar la suscripción
az login
az account set --subscription "TU_ID_DE_SUSCRIPCION"

# 3. (Opcional) Personalizar las variables de entorno
# Copia el ejemplo y edita el archivo .env según tus necesidades.
cp scripts/.env.example .env
nano .env

# 4. Desplegar la infraestructura 🔧
bash scripts/deploy.sh

# 5. Validar la instalación ✅
# Este script comprueba que todo funciona y cumple con los guardarraíles de coste.
bash scripts/validate.sh

# 6. Destruir todo para evitar costes 🧹
# El script pedirá confirmación.
bash scripts/destroy.sh

# Para forzar la destrucción sin preguntas:
bash scripts/destroy.sh --force
💡 Consejo FinOps: Activa las VMs Spot para un ahorro de hasta el 70%. Simplemente ajusta la variable DEPLOY_USE_SPOT=true en el archivo .env.
