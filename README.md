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

🌐 Internet → 🔗 IP Pública → ⚖️ Standard Load Balancer  
↙︎ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↘︎  
🖥️ VM-01 (AZ 1) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 🖥️ VM-02 (AZ 2)

### **Componentes y Justificación FinOps**

| Componente            | SKU / Tamaño           | Justificación de Coste (FinOps)                                          |
|-----------------------|------------------------|---------------------------------------------------------------------------|
| Máquina Virtual (VM)  | `Standard_B1s`         | El tamaño "burstable" más económico para demos productivas.              |
| Disco del SO          | `Standard SSD 64 GiB`  | Más barato que Premium, suficiente para contenido web estático.          |
| Balanceador de Carga  | `Standard (Z-redundant)` | La opción multi-AZ más asequible.                                       |
| IP Pública            | `Standard`             | Necesaria para el frontend y con redundancia de zona.                    |

---

## 🚀 Guía Rápida

### **1. Prerrequisitos**

- Azure CLI ≥ 2.60 (`az version`)
- Bash 4+ (se recomienda WSL 2 con Ubuntu 24.04)
- `jq` y `curl` instalados
- Rol de **Contribuidor** en la suscripción de Azure

### **2. Pasos de Despliegue**

```bash
# Clonar el repositorio
git clone https://github.com/jgaragorry/Load_Balancer_Ha_2vms.git
cd Load_Balancer_Ha_2vms

# Iniciar sesión y configurar la suscripción
az login
az account set --subscription "TU_ID_DE_SUSCRIPCION"

# Personalizar las variables de entorno
cp scripts/.env.example .env
nano .env

# Desplegar la infraestructura
bash scripts/deploy.sh

# Validar instalación
bash scripts/validate.sh

# Destruir todo para evitar costes
bash scripts/destroy.sh

# Destrucción forzada
bash scripts/destroy.sh --force
```

💡 Consejo FinOps: Activa las VMs Spot para ahorrar hasta un 70% (`DEPLOY_USE_SPOT=true` en `.env`).

---

## 📂 Estructura del Repositorio

```
.
├── README.md
└── scripts/
    ├── deploy.sh
    ├── validate.sh
    └── destroy.sh
```

### 📜 Scripts Detallados

| Script        | Descripción                                                                 |
|---------------|------------------------------------------------------------------------------|
| deploy.sh     | Crea la infraestructura completa y muestra la URL final del frontend.       |
| validate.sh   | Valida el estado del LB y de las VMs, incluyendo tamaño y estado.           |
| destroy.sh    | Elimina todo de forma segura y verifica su correcta eliminación.            |

---

## 🔒 Seguridad

- **NSG:** HTTP (80) abierto; SSH (22) solo desde tu IP
- **JIT:** Opcional con `ENABLE_JIT=true`
- **Autenticación:** SSH key gestionada (sin contraseñas)
- **Aislamiento:** Grupo de recursos dedicado

---

## 📊 Estimación de Costes

| Recurso            | Cantidad | Precio/Hora (USD) | Mensual (730h) |
|--------------------|----------|-------------------|----------------|
| VM B1s             | 2        | $0.022            | $32.12         |
| Disco SSD 64 GiB   | 2        | $0.005            | $7.30          |
| Load Balancer Std  | 1        | $0.025            | $18.25         |
| **Total Estimado** |          |                   | **≈ $57.67**   |

💡 1 hora de laboratorio ≈ $0.08. No olvides ejecutar `destroy.sh`.

---

## 🏷️ Convención de Etiquetas (Tags)

| Clave       | Ejemplo              | Motivo                                 |
|-------------|----------------------|----------------------------------------|
| Project     | Demo-HALB            | Agrupación lógica                      |
| Owner       | tu_email@dominio.com | Identificación del responsable         |
| Environment | Dev                  | Dev, QA, Prod                          |
| CostCenter  | CC-1234              | Seguimiento FinOps                     |
| DeleteBy    | YYYY-MM-DD           | Limpieza automática recomendada        |

---

## 📚 Referencias

- Azure Well-Architected Framework – Cost Optimization  
- [Documentación Azure Load Balancer](https://learn.microsoft.com/en-us/azure/load-balancer/)  
- FinOps Foundation – Cost Optimization on Azure

📅 Actualizado el 1 de julio de 2025
