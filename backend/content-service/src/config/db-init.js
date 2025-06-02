const mongoose = require('mongoose');
const Category = require('../models/category.model');
const logger = require('../utils/logger');

const initializeDatabase = async () => {
  try {
    const count = await Category.countDocuments();
    
    if (count === 0) {
      logger.info('Initializing default categories...');
      
      const defaultCategories = [
        {
          name: 'Engineering',
          description: 'Questions about engineering subjects and practices',
          color: '#1976D2',
          icon: 'engineering'
        },
        {
          name: 'Computer Science',
          description: 'Programming, algorithms, software development',
          color: '#388E3C',
          icon: 'computer'
        },
        {
          name: 'Business',
          description: 'Business management, entrepreneurship, economics',
          color: '#F57C00',
          icon: 'business'
        },
        {
          name: 'Mathematics',
          description: 'Pure and applied mathematics questions',
          color: '#7B1FA2',
          icon: 'calculate'
        },
        {
          name: 'Sciences',
          description: 'Physics, chemistry, biology and other sciences',
          color: '#C62828',
          icon: 'science'
        },
        {
          name: 'General',
          description: 'General questions about EPF Africa and student life',
          color: '#455A64',
          icon: 'school'
        }
      ];
      
      await Category.insertMany(defaultCategories);
      logger.info('Default categories created successfully');
    }
  } catch (error) {
    logger.error('Error initializing database:', error);
  }
};

module.exports = initializeDatabase;
