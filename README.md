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

## 🧑‍🏫 Autor
Jose Garagorry — Instructor Especialista en Azure Networking

---

🎓 Este laboratorio está optimizado para estudiantes y profesionales que deseen comprender de forma práctica:
- Alta disponibilidad en Azure
- Balanceo de carga con bajo costo
- Automatización de infraestructura
- Validación efectiva desde CLI y Portal

> Incluye buenas prácticas de **etiquetado**, principios **FinOps**, y una estructura didáctica para principiantes y autodidactas.
