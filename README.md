# Velasquez Gongora , Bruno Martin


## Arquitectura del Sistema

El flujo de trabajo implementado es el siguiente:

1. Recepcion: Un API Gateway recibe la imagen via solicitud HTTP POST
2. Carga Segura: La funcion Upload Lambda procesa la solicitud, guarda la imagen original en un bucket S3 protegido en una subred privada, y encola un mensaje en SQS
3. Mensajeria Asincrona: SQS actua como un buffer, asegurando que las imagenes se procesen de manera confiable. Si un mensaje falla multiples veces, se redirige a una Dead Letter Queue 
4. Procesamiento: La funcion Crop Lambda es disparada por SQS, descarga la imagen de S3, la redimensiona a 300x300 utilizando la libreria sharp y guarda la version procesada en una carpeta distinta dentro de S3

## Tecnologias Utilizadas

- Cloud Provider: Amazon Web Services (AWS)
- IaC: Terraform
- Backend: Node.js (AWS Lambda)
- Librerias principales: aws-sdk/client-s3, aws-sdk/client-sqs, sharp

## Seguridad, Costos y Autenticacion

- Autenticacion Segura (Cross-Account): No se utilizan credenciales estaticas de usuarios IAM en el archivo providers.tf. El despliegue se realiza utilizando una cuenta secundaria mediante llaves temporales de sesion, asumiendo los permisos delegados desde la cuenta primaria.
- Red Privada: Las funciones Lambda operan dentro de subredes privadas en una VPC, accediendo a S3 y SQS a traves de VPC Endpoints internos
- Control de Costos: Implementacion de reglas de ciclo de vida para la eliminacion automatica de archivos en S3 despues de 24 horas.

## Estructura del Repositorio

- /iac: Archivos de configuracion de Terraform.
- /src: Codigo fuente de las funciones Lambda (Node.js).

## Requisitos de Despliegue

- AWS CLI configurado con las credenciales temporales de la cuenta secundaria.
- Terraform instalado.
- Node.js para la instalacion de dependencias (se requiere compilar la libreria sharp para arquitectura Linux antes del despliegue).