Azure HA Load Balancer with Two Linux VMs – FinOps‑Optimised Reference

Propósito  Desplegar un front‑end web altamente disponible y de muy bajo coste en Azure usando un Load Balancer Standard y dos VMs Linux. Todo automatizado con Bash + Azure CLI (WSL Ubuntu 24.04 LTS). Incluye buenas prácticas de FinOps, seguridad y un teardown fiable para evitar cargos inesperados.

📁 Estructura del repositorio

.

├── README.md # Esta guía 📖

└── scripts/

├── deploy.sh # Aprovisiona toda la pila

├── validate.sh # Comprueba salud + guard‑rails de coste

└── destroy.sh # Limpieza completa (espera a que desaparezca el RG)

1️⃣ Arquitectura

Internet → Public IP → Standard Load Balancer

↙︎ ↘︎

VM‑01 (AZ 1) VM‑02 (AZ 2)

↳ Availability Set (si la región no soporta Zonas)

Componente

SKU / Tamaño

Justificación FinOps

VM

Standard\_B1s

Tamaño burstable más barato para demos productivas

Disco SO

Standard SSD 64 GiB

Más económico que Premium; suficiente para un web estático

Load Balancer

Standard (Z‑red.)

Opción multi‑AZ más barata

Public IP

Standard

Necesaria para el front‑end; redundante por zona

2️⃣ Guía rápida

\# 0) Clonar

git clone && cd azure-ha-loadbalancer-repo

\# 1) Login y subscripción

az login

az account set --subscription ""

\# 2) Personalizar variables (opcional)

cp scripts/.env.example .env && nano .env

\# 3) Desplegar 🔧

bash scripts/deploy.sh

\# 4) Validar ✅

bash scripts/validate.sh

\# 5) Destruir 🧹

\# Interactivo

bash scripts/destroy.sh

\# Forzar sin preguntas

bash scripts/destroy.sh --force

Tip 💰  Activa Spot VMs (DEPLOY\_USE\_SPOT=true) y el coste baja ~70 %.

3️⃣ Convención de etiquetas (tags)

Clave

Ejemplo

Motivo

Project

Demo-HALB

Agrupación lógica

Owner

Responsabilidad

Environment

Dev

Etapa de ciclo de vida

CostCenter

CC‑1234

Mapeo FinOps

DeleteBy

YYYY‑MM‑DD

Aviso auto‑limpieza

Todas las etiquetas se heredan en cada recurso → facilitan análisis de costes.

4️⃣ Seguridad 🔒

NSG permite solo HTTP 80 (Internet) y SSH 22 solo desde tu IP.

JIT SSH opcional (ENABLE\_JIT=true).

Clave SSH gestionada; sin contraseñas.

RG dedicado para aislar y limitar el blast‑radius.

destroy.sh espera hasta que Azure confirme que no queda nada.

5️⃣ Costes 📊

Recurso

Cant

Precio hora

Mensual (730 h)

VM B1s

2

$0.022

$32.12

Disco SSD 64 GiB

2

$0.005

$7.30

Load Balancer Std

1

$0.025

$18.25

Total estimado

≈ $57.67/mes

Coste para laboratorio de 1 hora

≈ $0.08 (57.67 / 730). Destruye con destroy.sh tras la práctica para evitar cargos extra.

6️⃣ Qué hace cada script

Script

Descripción

deploy.sh

Crea RG, VNet, NSG, IP pública, Load Balancer, dos NICs y dos VMs Ubuntu 22.04 con NGINX vía cloud‑init. Añade las NICs al backend pool y muestra la URL.

validate.sh

Comprueba HTTP 200 en el LB, verifica que las VMs son B1s y están running. Falla si algo se desvía.

destroy.sh

Borra el RG; con --force ignora confirmación. Hace poll cada 10 s hasta que el grupo deja de existir.

7️⃣ Requisitos previos

Azure CLI ≥ 2.60 (az version)

Bash 4+ (WSL 2 / Ubuntu 24.04)

jq y curl

Rol Contributor en la subscripción

8️⃣ Pasarela de seguridad y guard‑rails

El script validate.sh sirve de checklist FinOps:

Prueba salud HTTP.

Verifica tamaños burstable y estado running.

Si configuras MAX\_DAILY\_BUDGET, avisa cuando el gasto previsto supera tu umbral.

9️⃣ Referencias

Azure Well‑Architected Framework – Cost Optimisation

Documentación Azure Load Balancer

FinOps Foundation – Azure Cost Optimisation

README actualizado: 01‑Jul‑2025
