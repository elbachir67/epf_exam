const mongoose = require('mongoose');

const QuestionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Question title is required'],
    trim: true,
    minlength: [5, 'Title must be at least 5 characters'],
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  content: {
    type: String,
    required: [true, 'Question content is required'],
    trim: true,
    minlength: [10, 'Content must be at least 10 characters'],
    maxlength: [5000, 'Content cannot exceed 5000 characters']
  },
  authorId: {
    type: String,
    required: true,
    index: true
  },
  authorName: {
    type: String,
    required: true
  },
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: [true, 'Category is required'],
    index: true
  },
  tags: [{
    type: String,
    trim: true,
    maxlength: [30, 'Tag cannot exceed 30 characters']
  }],
  viewCount: {
    type: Number,
    default: 0,
    min: 0
  },
  answerCount: {
    type: Number,
    default: 0,
    min: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isClosed: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Text search index
QuestionSchema.index({
  title: 'text',
  content: 'text',
  tags: 'text'
});

// Compound indexes
QuestionSchema.index({ categoryId: 1, createdAt: -1 });
QuestionSchema.index({ authorId: 1, createdAt: -1 });
QuestionSchema.index({ isActive: 1, createdAt: -1 });

// Virtual for answers
QuestionSchema.virtual('answers', {
  ref: 'Answer',
  localField: '_id',
  foreignField: 'questionId'
});

module.exports = mongoose.model('Question', QuestionSchema);
