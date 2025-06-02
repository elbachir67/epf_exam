const mongoose = require('mongoose');

const CategorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Category name is required'],
    unique: true,
    trim: true,
    minlength: [2, 'Category name must be at least 2 characters'],
    maxlength: [50, 'Category name cannot exceed 50 characters']
  },
  description: {
    type: String,
    required: [true, 'Category description is required'],
    trim: true,
    maxlength: [200, 'Description cannot exceed 200 characters']
  },
  color: {
    type: String,
    default: '#007bff',
    match: [/^#[0-9A-F]{6}$/i, 'Invalid color format']
  },
  icon: {
    type: String,
    default: 'book'
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
CategorySchema.index({ name: 1 });
CategorySchema.index({ isActive: 1 });

// Virtual for question count
CategorySchema.virtual('questionCount', {
  ref: 'Question',
  localField: '_id',
  foreignField: 'categoryId',
  count: true
});

module.exports = mongoose.model('Category', CategorySchema);
