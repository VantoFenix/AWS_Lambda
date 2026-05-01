const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");

const s3 = new S3Client({});
const sqs = new SQSClient({});

exports.handler = async (event) => {
    try {
        // 1 Extraer datos del evento (API Gateway)
        const body = JSON.parse(event.body);
        const buffer = Buffer.from(body.image, 'base64');
        const fileName = `${Date.now()}-${body.name}`;
        
        const bucketName = process.env.BUCKET_NAME;
        const queueUrl = process.env.QUEUE_URL;

        // 2 Subir imagen original a S3
        await s3.send(new PutObjectCommand({
            Bucket: bucketName,
            Key: `originals/${fileName}`,
            Body: buffer,
            ContentType: "image/jpeg"
        }));

       
        await sqs.send(new SendMessageCommand({
            QueueUrl: queueUrl,
            MessageBody: JSON.stringify({
                fileName: fileName,
                bucketName: bucketName
            })
        }));

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Imagen recibida y en cola", file: fileName })
        };
    } catch (error) {
        console.error(error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Error procesando la subida" })
        };
    }
};