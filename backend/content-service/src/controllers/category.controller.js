const Category = require('../models/category.model');
const { validationResult } = require('express-validator');
const logger = require('../utils/logger');

class CategoryController {
  async getAllCategories(req, res) {
    try {
      const categories = await Category.find({ isActive: true })
        .sort({ name: 1 })
        .select('-__v');
      
      res.json({
        success: true,
        data: categories,
        count: categories.length
      });
    } catch (error) {
      logger.error('Error fetching categories:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch categories'
      });
    }
  }

  async createCategory(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { name, description, color, icon } = req.body;
      
      const existingCategory = await Category.findOne({ 
        name: { $regex: new RegExp(`^${name}$`, 'i') }
      });
      
      if (existingCategory) {
        return res.status(400).json({
          success: false,
          error: 'Category with this name already exists'
        });
      }

      const category = new Category({
        name,
        description,
        color: color || '#007bff',
        icon: icon || 'book'
      });

      const savedCategory = await category.save();
      
      logger.info(`Category created: ${savedCategory.name}`);
      
      res.status(201).json({
        success: true,
        data: savedCategory
      });
    } catch (error) {
      logger.error('Error creating category:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create category'
      });
    }
  }

  async getCategoryById(req, res) {
    try {
      const { id } = req.params;
      
      const category = await Category.findById(id)
        .populate('questionCount')
        .select('-__v');
        
      if (!category || !category.isActive) {
        return res.status(404).json({
          success: false,
          error: 'Category not found'
        });
      }

      res.json({
        success: true,
        data: category
      });
    } catch (error) {
      logger.error('Error fetching category:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch category'
      });
    }
  }

  async updateCategory(req, res) {
    try {
      const { id } = req.params;
      const updates = req.body;
      
      const category = await Category.findByIdAndUpdate(
        id,
        updates,
        { new: true, runValidators: true }
      );
      
      if (!category) {
        return res.status(404).json({
          success: false,
          error: 'Category not found'
        });
      }
      
      logger.info(`Category updated: ${category.name}`);
      
      res.json({
        success: true,
        data: category
      });
    } catch (error) {
      logger.error('Error updating category:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update category'
      });
    }
  }

  async deleteCategory(req, res) {
    try {
      const { id } = req.params;
      
      const category = await Category.findByIdAndUpdate(
        id,
        { isActive: false },
        { new: true }
      );
      
      if (!category) {
        return res.status(404).json({
          success: false,
          error: 'Category not found'
        });
      }
      
      logger.info(`Category deactivated: ${category.name}`);
      
      res.json({
        success: true,
        message: 'Category deleted successfully'
      });
    } catch (error) {
      logger.error('Error deleting category:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to delete category'
      });
    }
  }
}

module.exports = new CategoryController();
