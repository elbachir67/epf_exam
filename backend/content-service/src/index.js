const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const logger = require('./utils/logger');
require('dotenv').config();

// Import routes
const categoryRoutes = require('./routes/category.routes');
const questionRoutes = require('./routes/question.routes');
const answerRoutes = require('./routes/answer.routes');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/epfafrica';

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) }}));
app.use('/api', limiter);

// Connect to MongoDB
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => {
  logger.info('✅ Connected to MongoDB');
})
.catch(err => {
  logger.error('❌ MongoDB connection error:', err);
  process.exit(1);
});

// Routes
app.use('/api/categories', categoryRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/answers', answerRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: 'epf-africa-content-service',
    version: '1.0.0',
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'EPF Africa Content Service API',
    version: '1.0.0',
    status: 'Running',
    endpoints: {
      health: '/health',
      categories: '/api/categories',
      questions: '/api/questions',
      answers: '/api/answers'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(err.stack);
  
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  
  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    path: req.originalUrl
  });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`🚀 EPF Africa Content Service running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    mongoose.connection.close();
  });
});

module.exports = app;
