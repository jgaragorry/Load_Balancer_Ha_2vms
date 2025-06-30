
# 🧪 Laboratorio Azure: Network Load Balancer con Alta Disponibilidad

## 📘 Descripción General
Este laboratorio permite desplegar una arquitectura de alta disponibilidad en Azure usando un **Load Balancer (NLB)** tipo Basic, conectado a **dos máquinas virtuales (VMs)** Linux en un Availability Set. Las VMs tienen instalado **Nginx** para responder al tráfico HTTP.

Es ideal para estudiantes que desean entender:
- Balanceo de carga nivel TCP en Azure
- Alta disponibilidad con Availability Sets
- Configuración de reglas de NSG y probes de salud

---

## ✅ Requisitos Previos
- Tener una cuenta de Azure activa
- Tener instalado [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Acceso a terminal Bash (Linux, WSL o Cloud Shell)

---

## 📂 Archivos incluidos
- `create_lab_nlb.sh` → script principal para crear toda la infraestructura
- `delete_lab_nlb.sh` → script para eliminar todos los recursos del laboratorio
- `verify_lab_nlb.sh` → script para verificar que el laboratorio funciona correctamente

---

## 🚀 Pasos de Ejecución

1. **Iniciar sesión en Azure:**
```bash
az login
```

2. **Dar permisos de ejecución y correr el script:**
```bash
chmod +x create_lab_nlb.sh
./create_lab_nlb.sh
```

3. **Esperar la salida final:**

Verás algo como:
```
✅ Laboratorio creado correctamente.
🌐 Accede al balanceador en: http://<IP-PUBLICA>
```

4. **Verifica en el navegador:**

Abre `http://<IP-PUBLICA>` y deberías ver uno de los siguientes mensajes:
- "Hola desde VM1"
- "Hola desde VM2"

Al refrescar varias veces, verás alternancia si el balanceo funciona.

---

## 🧪 Verificación del Laboratorio

Una vez desplegado, puedes verificar automáticamente con:

```bash
chmod +x verify_lab_nlb.sh
./verify_lab_nlb.sh
```

Este script realiza:
- Obtención y validación de la IP pública
- Peticiones HTTP repetidas con `curl`
- Estado del Load Balancer y las VMs

---

## 🧹 Limpieza de Recursos
Para evitar costos innecesarios, ejecuta:

```bash
chmod +x delete_lab_nlb.sh
./delete_lab_nlb.sh
```

Este script elimina el grupo de recursos completo (`rg-nlb-lab`) sin pedir confirmación y espera a que se elimine completamente antes de finalizar.

---

## ⚠️ Errores Comunes y Soluciones

### ❌ Error: `InvalidResourceReference` (http-probe not found)
**Causa:** El probe de salud fue referenciado antes de crearse.
**Solución:** El script ya ha sido corregido para crear el probe **antes** de la regla de balanceo.

### ❌ No se puede acceder por HTTP
**Verifica:**
- Que el NSG permita el puerto 80
- Que Nginx esté activo: `sudo systemctl status nginx`

### ❌ Error: `--backend-pool-name` no reconocido
**Causa:** Uso incorrecto del parámetro en la asociación de NIC al backend pool.
**Solución:** El parámetro fue eliminado del script y se usa solo `--address-pool`.

### ⚠️ Advertencia: `numberOfProbes is not respected`
**Mensaje:**
```
The property "numberOfProbes" is not respected. [...] please leverage the property "probeThreshold" instead.
```

**Explicación:** Azure ya no utiliza `numberOfProbes` en los probes de salud. En su lugar, debes usar `--probe-threshold` para indicar cuántas fallas o éxitos consecutivos se necesitan para marcar un backend como "sano" o "no disponible".

**Solución:** El script fue corregido para incluir únicamente `--probe-threshold`, como recomienda Azure.

---

## 🧠 Buenas Prácticas Enseñadas
- Uso de Availability Sets para alta disponibilidad
- Configuración de Load Balancer Basic
- Asociación de NSG a VM directamente
- Script automatizado y reutilizable con variables claras

---

## 📚 Recursos Recomendados
- [Documentación Azure Load Balancer](https://learn.microsoft.com/es-es/azure/load-balancer/load-balancer-overview)
- [NGINX Ubuntu Setup](https://ubuntu.com/server/docs/service-nginx)
- [Azure CLI Reference](https://learn.microsoft.com/es-es/cli/azure/)

---

© 2025 | GMTech Labs para uso educativo. Compartir con fines académicos.
