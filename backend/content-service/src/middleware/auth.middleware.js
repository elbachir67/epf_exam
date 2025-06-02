const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

const JWT_SECRET = process.env.JWT_SECRET || 'epf_africa_secret_key_2025_very_long_and_secure_string_for_production';

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    logger.warn('No token provided');
    return res.status(401).json({
      success: false,
      error: 'No token provided'
    });
  }
  
  const token = authHeader.substring(7);
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Le token de Spring Boot utilise 'sub' pour le username
    // On doit récupérer l'ID et le username depuis le token
    req.user = {
      username: decoded.sub || decoded.username,
      userId: decoded.id || decoded.userId || decoded.sub // Utiliser l'ID si disponible, sinon le username
    };
    
    logger.info(`Token verified for user: ${req.user.username} (ID: ${req.user.userId})`);
    next();
  } catch (error) {
    logger.error('Token verification error:', error.message);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
};

const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.user = {
        username: decoded.sub || decoded.username,
        userId: decoded.id || decoded.userId || decoded.sub
      };
      logger.info(`Optional auth - user: ${req.user.username}`);
    } catch (error) {
      logger.warn('Optional auth - invalid token:', error.message);
    }
  }
  
  next();
};

module.exports = { verifyToken, optionalAuth };