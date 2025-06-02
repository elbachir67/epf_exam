// Add this after MongoDB connection
const initializeDatabase = require('./config/db-init');

// After successful MongoDB connection
mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(async () => {
  logger.info('✅ Connected to MongoDB');
  await initializeDatabase();
})
.catch(err => {
  logger.error('❌ MongoDB connection error:', err);
  process.exit(1);
});
