# Velasquez Gongora, Bruno Martin

## Resumen del Proyecto

Este sistema automatiza la carga y el procesamiento de imagenes en la nube de AWS utilizando una arquitectura orientada a eventos. El objetivo principal es que un usuario pueda enviar una foto por una API y que el sistema la guarde y la procese de forma asincrona sin bloquear la respuesta inicial.

## Arquitectura y Flujo de Trabajo

1. Entrada de datos: El API Gateway recibe un JSON con la imagen en base64.
2. Procesamiento de carga: La funcion Upload Lambda recibe los datos, decodifica la imagen y la guarda en un bucket de S3. Luego envia un mensaje a una cola SQS con la informacion del archivo.
3. Comunicacion: SQS maneja la mensajeria para que si la segunda funcion esta ocupada o falla, el mensaje no se pierda.
4. Procesamiento de imagen: La funcion Crop Lambda se activa con el mensaje de SQS, descarga la imagen de la carpeta originals en S3, la recorta y deberia guardarla en una ruta distinta.

## Configuracion del Entorno y Particularidades Tecnicas

se han realizado ajustes especificos en la infraestructura que son criticos:

- Memoria y Tiempos: La Lambda de carga requiere al menos 512 MB de memoria y un timeout de 29 segundos. Esto es necesario porque al estar dentro de una VPC, el arranque en frio  y la conexion inicial a la red privada pueden tardar mas de los 3 segundos que vienen por defecto en AWS
- Seguridad de Red: Las Lambdas estan en subredes privadas. Para que puedan comunicarse con otros servicios de AWS, el Security Group debe tener una regla de salida  para el protocolo TCP en el puerto 443 o permitir todo el trafico de salida, si no fuera asi lapeticion se quedara colgada


## importante problema con la Libreria Sharp 

Un detalle importante que encontre durante el desarrollo es el manejo de la libreria sharp. Como el desarrollo se hizo en una laptop con Windows y las Lambdas de AWS corren sobre Linux, hay una incompatibilidad de binarios. 

Si se hace un npm install normal en Windows, la funcion de procesamiento fallara con un error y para solucionar esto antes de subir el codigo, se debe instalar la libreria especificamente para el entorno de destino con el siguiente comando dentro de la carpeta de la funcion:

npm install --platform=linux --arch=x64 sharp

## Pasos para el Despliegue

1. Preparacion de archivos: Ir a las carpetas de las funciones dentro de src e instalar las dependencias. En la funcion de crop, usar el comando mencionado arriba para compatibilidad con Linux.
2. Inicializacion: Dentro de la carpeta iac, ejecutar terraform init para descargar los proveedores necesarios.
3. Aplicacion: Ejecutar terraform apply -auto-approve. Es normal que la primera vez tarde varios minutos por la creacion de la VPC y el NAT Gateway.
4. Pruebas: Usar Postman para enviar un POST al endpoint generado. Si la primera peticion da un error de tiempo, intentar una segunda vez ya que la red privada suele tardar en activarse la primera vez.
5. Limpieza: Al terminar todas las pruebas y capturas de pantalla, es obligatorio ejecutar terraform destroy para evitar cobros innecesarios por los recursos de red que no entran en la capa gratuita.

## Tecnologias

- Amazon Web Services (VPC, Lambda, S3, SQS, API Gateway, CloudWatch)
- Terraform para infraestructura como codigo
- Node.js 18.x para la logica del backend