const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({});

exports.handler = async (event) => {
    for (const record of event.Records) {
        try {
            //  Obtener datos del mensaje de SQS
            const { fileName, bucketName } = JSON.parse(record.body);
            console.log(`Procesando archivo: ${fileName} del bucket: ${bucketName}`);

            //  Descargar la imagen de S3 
            const getObjectParams = {
                Bucket: bucketName,
                Key: `originals/${fileName}`
            };
            const response = await s3.send(new GetObjectCommand(getObjectParams));
            const streamToBuffer = (stream) =>
                new Promise((resolve, reject) => {
                    const chunks = [];
                    stream.on("data", (chunk) => chunks.push(chunk));
                    stream.on("error", reject);
                    stream.on("end", () => resolve(Buffer.concat(chunks)));
                });
            
            const imageBuffer = await streamToBuffer(response.Body);

            //  Procesar con SHARP 
            const processedBuffer = await sharp(imageBuffer)
                .resize(300, 300, { fit: 'cover' })
                .toBuffer();

            //  Subir la imagen procesada a S3 
            await s3.send(new PutObjectCommand({
                Bucket: bucketName,
                Key: `processed/${fileName}`,
                Body: processedBuffer,
                ContentType: "image/jpeg"
            }));

            console.log(`Imagen ${fileName} procesada exitosamente.`);

        } catch (error) {
            console.error("Error en el procesamiento:", error);
        
            throw error; 
        }
    }
};