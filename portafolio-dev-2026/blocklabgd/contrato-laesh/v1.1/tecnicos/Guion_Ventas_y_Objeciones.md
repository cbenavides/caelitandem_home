# GUION DE VENTAS Y MANEJO DE OBJECIONES (Interno)
**Proyecto:** Laboratorios Clínicos LAESH

Este documento es una guía interna de negociación. Contiene las respuestas estratégicas a las objeciones más duras que el cliente podría poner sobre la mesa, especialmente respecto a los precios y la propiedad del código.

---

## 1. ¿Por qué NO mencionar la "Propiedad del Código" en el Resumen Comercial?
En el `Resumen_Oferta_Servicios.md` solo se vende **valor** (ahorro de tiempo, automatización, cero errores). 

Si tú, en el PDF que les presentas para venderles, pones explícitamente: *"Nota: El código es mío y lo puedo revender"*, estás cometiendo un suicidio comercial. 
**¿Por qué?** Porque le estás sembrando una duda que el cliente ni siquiera tenía. Le estás diciendo: *"Miren, les voy a vender esto, pero que sepan que voy a hacer negocio con otros usando su dinero"*. 

Esa regla de "Licenciamiento No Exclusivo" pertenece **exclusivamente al ámbito legal** (y ahí está, bien protegida en el Contrato Base). Si no la leen, perfecto. Si la leen y preguntan, entonces aplicas la respuesta del punto 2. Nunca la uses como herramienta de marketing porque juega en tu contra.

---

## 2. Defensa: "Me estás cobrando por algo que vas a revender"
Si el contador o el dueño del laboratorio lee el contrato y te dice algo como: 
*👉 "Oye Carlos, dice el contrato que tú te quedas el código. Básicamente yo te estoy pagando 80 mil pesos para que armes tu negocio y luego vayas a revenderle 'nuestra idea' a la competencia. Si yo te voy a financiar el sistema, hazme un súper descuento".*

**Tu respuesta coloquial (Aprender y adaptar a tus palabras):**
> *"A ver doctor/contador, entiendo perfecto su punto, pero es exactamente al revés.* 
>
> *Si ustedes quisieran que yo les desarrolle un sistema exclusivo, es decir, que yo les entregue los derechos de autor, el código fuente y que yo nunca más pueda usar esta tecnología, un software médico de este nivel no les costaría 80 mil pesos... en el mercado andaría sobre los 250 mil o 300 mil pesos, mínimo.*
>
> *Aquí nadie está inventando el hilo negro, es un flujo de laboratorio estándar. El precio de 80 mil pesos **ya trae aplicado el descuento** gigantesco por el hecho de que me quedo con el código base. Básicamente, les estoy subsidiando más del 70% del costo real del software. Les estoy cobrando únicamente mis horas de trabajo para adaptar el sistema a sus computadoras, a su WhatsApp y a sus colores. Es gracias a este modelo que ustedes pueden tener un sistema de primer nivel a una fracción de lo que les costaría mandarlo a hacer como dueños absolutos."*

**Por qué funciona:** Con este argumento los desarmas por completo. Pasas de ser el "aprovechado" a ser el aliado que les está ahorrando 200 mil pesos.

---

## 3. Manejo de Precios y Concesiones (Tu Piso Absoluto)

Si te intentan exprimir el precio del **Paquete Integral (Cotizado en $80,000 MXN)**, esta es tu escalera de negociación:

*   **Tu Posición Inicial (Lo ideal): $80,000 MXN.**
    *   Mantente firme aquí al principio. Muestra todo el valor que aporta.
*   **La Concesión Estratégica (Excelente trato): $75,000 MXN.**
    *   *El diálogo:* "Miren, me interesa muchísimo que LAESH sea mi caso de éxito insignia en el sector salud. Si cerramos el Paquete Completo esta semana y me ayudan a grabar un testimonio cuando terminemos, les absorbo otros 5 mil pesos de mi bolsa. Se los dejo en 75 cerrados".
    *   *La matemática:* Te pagan $25,000 MXN mensuales por 3 meses. Súper sano.
*   **Tu Piso Absoluto (El límite de la dignidad): $65,000 MXN.**
    *   *La matemática:* 65k / 3 meses = $21,600 MXN mensuales. 
    *   Si bajas de aquí, vas a terminar odiando el proyecto. Programar integraciones médicas con WhatsApp por menos de 20 mil pesos al mes es devaluar tu trabajo y tu experiencia. Si el cliente no tiene 65 mil pesos para invertir en automatizar todo su laboratorio, entonces no son el cliente corporativo que buscas, y es mejor venderles solo la Web Plus (Opción 2) o la Web Básica (Opción 1).

---

## 4. El "WhatsApp Stopper": Cómo venderlo y explicarlo

A partir de la **Opción 2**, el sistema se conecta a la infraestructura mundial de Meta (Facebook/WhatsApp). Meta cobra en dólares por cada conversación iniciada. Para que el cliente no tenga miedo de que le llegue una factura de 50 mil pesos por un error o un ataque de *spam*, inventamos el **WhatsApp Stopper**.

**¿Cómo se lo explicas al cliente?**
> *"Doctor, la API Oficial de WhatsApp Cloud no es gratis. Meta (Facebook) cobra unos centavos por cada mensaje que enviamos. Si alguna vez el sistema se vuelve loco, o un competidor intenta hackear su página haciendo mil solicitudes por segundo, Meta les podría mandar una factura de miles de pesos al final del mes.*
> *Para proteger su dinero, yo les programé un 'WhatsApp Stopper' (un disyuntor). Le vamos a poner un límite mensual configurable (ejemplo típico: $2,000 a $3,000 pesos mensuales, según el volumen de pacientes). Si el sistema llega a ese límite, corta inmediatamente la conexión con Meta para que no gasten un solo peso más sin su autorización. Y si les queda corto, ustedes me avisan y se lo ajusto en minutos."*

### Plan de Contingencia (¿Qué pasa si el Stopper se activa?)
Si a mitad de mes se les acaba el saldo (o se activa por seguridad), **el laboratorio no se detiene, pero se vuelve manual**:
1. **La Clínica (Portal Plus):** La recepcionista tendrá que descargar los PDFs del sistema y enviarlos manualmente a los pacientes desde un teléfono celular físico con "WhatsApp Web", exactamente como lo hacen hoy en día.
2. **Los Médicos (Bloc Digital):** Si el doctor genera una solicitud y el Stopper está activo, el sistema mostrará un aviso. El médico tendrá que imprimir la solicitud generada por el sistema en papel (o simplemente anotar el número de **Folio** en su receta médica) y dársela físicamente al paciente para que vaya al laboratorio.

### ¿Cuándo se reactiva?
1. **Modo Automático:** Se reactiva solito el **Día 1 del siguiente mes calendario**, cuando el contador mensual de Meta y de tu sistema se resetean a cero.
2. **Modo Manual (Bajo Demanda):** Si la clínica se quedó sin saldo el día 20 porque tuvieron muchísimo éxito y demasiados pacientes, el administrador de la clínica te puede llamar y decirte: *"Carlos, súbele el tope a $3,000 pesos, no nos importa pagarle más a Meta, queremos que siga en automático"*. Tú (con tu Póliza de Soporte) entras al servidor, les subes el límite, y el sistema vuelve a enviar WhatsApps ese mismo día.

---

## 5. Estrategia de Cierre: La Escalera 3 → 4 (El "Truco del Cuello de Botella")

Esta táctica es una de las más poderosas para cerrar la Opción 4. El objetivo es que el propio cliente llegue a la conclusión de que la necesita, sin que tú se la impongas.

**El guión:**
1. **Presenta la Opción 3 primero** como si fuera la estrella del catálogo. Muéstrale el Bloc Digital, el portal médico, la notificación automática de la orden al paciente. Deja que se emocione.
2. **Espera a que pregunte:** *"¿Y los resultados? ¿También se los mandamos automáticamente?"*
3. **Revela el cuello de botella** (no como crítica, sino como una limitante honesta del plan): *"Con la Opción 3 no, doctor. Los resultados los tiene que seguir mandando la recepcionista a mano, igual que hoy. Y aquí hay un detalle operativo: Meta bloquea el chat a las 24 horas si el paciente no contestó, así que no podrá usar el nuevo número automático para avisarles. Tendrá que hacerlo desde el teléfono viejo de la clínica."*
4. **Deja que el cliente calcule:** El paciente recibe la orden desde el número nuevo y los resultados desde el número viejo. Dos conversaciones. Confuso para el paciente, doble trabajo para la recepcionista.
5. **Entonces presentas la Opción 4** como la solución natural: *"La Opción 4 cierra ese ciclo. El químico guarda el PDF en su computadora y el sistema hace el resto: lo convierte a imagen y se lo manda al paciente por WhatsApp desde ese mismo número automático. La recepcionista no toca nada."*

**Por qué funciona:** El cliente siente que él descubrió el problema y que tú solo le ofreciste la solución. No percibe presión de venta.
