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
