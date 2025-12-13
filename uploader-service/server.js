const express = require('express');
const multer = require('multer');
const Minio = require('minio');
const app = express();
const PORT = 3001;

// Настройка multer для загрузки в память
const upload = multer({ storage: multer.memoryStorage() });

// Настройка MinIO клиента
const minioEndpoint = process.env.MINIO_ENDPOINT || 'minio:9000';
const [host, port] = minioEndpoint.split(':');

const minioClient = new Minio.Client({
  endPoint: host,
  port: parseInt(port) || 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin'
});

const BUCKET_NAME = process.env.MINIO_BUCKET || 'uploads';

// Инициализация бакета при старте
async function initializeBucket() {
  try {
    const exists = await minioClient.bucketExists(BUCKET_NAME);
    if (!exists) {
      await minioClient.makeBucket(BUCKET_NAME, 'us-east-1');
      console.log(`Bucket "${BUCKET_NAME}" created successfully`);
    } else {
      console.log(`Bucket "${BUCKET_NAME}" already exists`);
    }
  } catch (err) {
    console.error('Error initializing bucket:', err);
  }
}

app.use(express.json());

// Endpoint для загрузки файла
app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    // Получаем информацию о пользователе из заголовков (от ForwardAuth)
    const userId = req.headers['x-user-id'] || 'anonymous';
    const userRole = req.headers['x-user-role'] || 'guest';

    const fileName = `${Date.now()}-${req.file.originalname}`;
    const fileBuffer = req.file.buffer;
    const fileSize = req.file.size;
    const contentType = req.file.mimetype;

    // Загружаем файл в MinIO
    await minioClient.putObject(
      BUCKET_NAME,
      fileName,
      fileBuffer,
      fileSize,
      {
        'Content-Type': contentType,
        'X-User-Id': userId,
        'X-User-Role': userRole
      }
    );

    console.log(`File uploaded: ${fileName} by user ${userId} (${userRole})`);

    res.json({
      success: true,
      message: 'File uploaded successfully',
      file: {
        name: fileName,
        originalName: req.file.originalname,
        size: fileSize,
        contentType: contentType,
        uploadedBy: userId,
        bucket: BUCKET_NAME
      }
    });
  } catch (err) {
    console.error('Upload error:', err);
    res.status(500).json({ error: 'Failed to upload file', details: err.message });
  }
});

// Endpoint для получения списка файлов
app.get('/upload/list', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || 'anonymous';
    const stream = minioClient.listObjects(BUCKET_NAME, '', true);
    const files = [];

    stream.on('data', (obj) => {
      files.push({
        name: obj.name,
        size: obj.size,
        lastModified: obj.lastModified,
        etag: obj.etag
      });
    });

    stream.on('error', (err) => {
      console.error('List error:', err);
      res.status(500).json({ error: 'Failed to list files' });
    });

    stream.on('end', () => {
      res.json({
        success: true,
        files: files,
        count: files.length,
        requestedBy: userId
      });
    });
  } catch (err) {
    console.error('List error:', err);
    res.status(500).json({ error: 'Failed to list files', details: err.message });
  }
});

// Endpoint для скачивания файла
app.get('/upload/download/:filename', async (req, res) => {
  try {
    const fileName = req.params.filename;
    const userId = req.headers['x-user-id'] || 'anonymous';

    // Получаем метаданные файла
    const stat = await minioClient.statObject(BUCKET_NAME, fileName);

    // Получаем поток данных файла
    const dataStream = await minioClient.getObject(BUCKET_NAME, fileName);

    res.setHeader('Content-Type', stat.metaData['content-type'] || 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);

    console.log(`File downloaded: ${fileName} by user ${userId}`);

    dataStream.pipe(res);
  } catch (err) {
    console.error('Download error:', err);
    if (err.code === 'NotFound') {
      res.status(404).json({ error: 'File not found' });
    } else {
      res.status(500).json({ error: 'Failed to download file', details: err.message });
    }
  }
});

// Endpoint для удаления файла
app.delete('/upload/:filename', async (req, res) => {
  try {
    const fileName = req.params.filename;
    const userId = req.headers['x-user-id'] || 'anonymous';
    const userRole = req.headers['x-user-role'] || 'guest';

    // Проверяем права (только админ может удалять)
    if (userRole !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin role required.' });
    }

    await minioClient.removeObject(BUCKET_NAME, fileName);

    console.log(`File deleted: ${fileName} by user ${userId}`);

    res.json({
      success: true,
      message: 'File deleted successfully',
      fileName: fileName
    });
  } catch (err) {
    console.error('Delete error:', err);
    res.status(500).json({ error: 'Failed to delete file', details: err.message });
  }
});

// Health check endpoint
app.get('/upload/health', (req, res) => {
  res.json({ status: 'healthy', service: 'uploader' });
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Uploader service listening on port ${PORT}`);
  console.log('Initializing MinIO bucket...');
  await initializeBucket();
  console.log('Uploader service is ready!');
});
