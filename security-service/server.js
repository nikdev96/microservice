const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());

// Простое хранилище токенов (в продакшене использовать БД)
const validTokens = new Map();
validTokens.set('valid-token-12345', { userId: '1', role: 'admin' });
validTokens.set('user-token-67890', { userId: '2', role: 'user' });

// Endpoint для получения токена (логин)
app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;

  // Простая проверка (в продакшене использовать хеширование паролей)
  if (username === 'admin' && password === 'admin') {
    return res.json({
      success: true,
      token: 'valid-token-12345',
      user: { id: '1', username: 'admin', role: 'admin' }
    });
  }

  if (username === 'user' && password === 'user') {
    return res.json({
      success: true,
      token: 'user-token-67890',
      user: { id: '2', username: 'user', role: 'user' }
    });
  }

  res.status(401).json({ success: false, message: 'Invalid credentials' });
});

// Endpoint для проверки токена (используется Traefik ForwardAuth)
app.get('/auth/verify', (req, res) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader) {
    return res.status(401).json({ message: 'No authorization header' });
  }

  const token = authHeader.replace('Bearer ', '');
  const user = validTokens.get(token);

  if (!user) {
    return res.status(401).json({ message: 'Invalid token' });
  }

  // Устанавливаем заголовки для передачи информации о пользователе
  res.setHeader('X-User-Id', user.userId);
  res.setHeader('X-User-Role', user.role);
  res.status(200).json({ message: 'Authorized', user });
});

// Endpoint для проверки здоровья сервиса
app.get('/auth/health', (req, res) => {
  res.json({ status: 'healthy', service: 'security' });
});

// Endpoint для получения информации о пользователе
app.get('/auth/me', (req, res) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader) {
    return res.status(401).json({ message: 'No authorization header' });
  }

  const token = authHeader.replace('Bearer ', '');
  const user = validTokens.get(token);

  if (!user) {
    return res.status(401).json({ message: 'Invalid token' });
  }

  res.json({ user });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Security service listening on port ${PORT}`);
  console.log('Available tokens:');
  console.log('  Admin: valid-token-12345 (username: admin, password: admin)');
  console.log('  User:  user-token-67890 (username: user, password: user)');
});
